package Web::Id::Certificate::Generator;

use 5.010;
use utf8;

BEGIN {
	$Web::Id::Certificate::Generator::AUTHORITY = 'cpan:TOBYINK';
	$Web::Id::Certificate::Generator::VERSION   = '0.001';
}

use Any::Moose 'X::Types::Moose' => [':all'];
use File::Temp qw();
use Path::Class qw();
use RDF::Trine qw(statement blank iri literal);
use Web::Id::Types ':all';
use Web::Id::Util;

use Any::Moose 'Role';

sub _openssl_path
{
	Path::Class::File->new(
		$^O eq 'Win32'
			? 'c:\\openssl\\bin\\openssl.exe'
			: '/usr/bin/openssl'
	)
}

sub generate
{
	my ($class, %options) = @_;
	
	my $openssl    = (delete $options{openssl_path}) // $class->_openssl_path;
	my $passphrase = (delete $options{passphrase})
		or confess "need to provide passphrase option";
	my $key_size   = (delete $options{key_size}) // 1024;
	my $sans       = (delete $options{subject_alt_names})
		or confess "need to provide subject_alt_names option";
	my $not_after  = (delete $options{not_after});
	my $dest       = (delete $options{cert_output})
		or confess "need to provide cert_output option";
	my $rdf_sink   = (delete $options{rdf_output})
		or confess "need to provide rdf_output option";
	
	my %subject = (
		C    => delete $options{subject_country},
		ST   => delete $options{subject_region},
		L    => delete $options{subject_locality},
		O    => delete $options{subject_org},
		CN   => delete $options{subject_cn},
		);
	
	confess "need to provide subject_cn option" unless $subject{CN};
	
	confess "unsupported options: ".(join q(, ), sort keys %options) if %options;
	
	my $days = $not_after
		? $not_after->delta_days( DateTime->now )->days
		: 365;
	
	my $tempdir = Path::Class::Dir->new( File::Temp->newdir );
	$tempdir->mkpath;
	
	open my $config, '>', $tempdir->file('openssl.cnf');
	say $config $_ for
		q([req]),
		q(default_bits = 1024),
		q(default_keyfile = privkey.pem),
		q(distinguished_name = req_distinguished_name),
		q(x509_extensions = v3_ca),
		q(prompt = no),
		q(),
		q([v3_ca]);
	
	say $config
		q(subjectAltName = ) .
		join q(,),
		map {
			my $value = $_->value;
			my $type = {
				rfc822Name                => 'email',
				uniformResourceIdentifier => 'URI',
			}->{ $_->type };
			$type ? (join q(:), $type, $value) : ();
		} @$sans;

	say $config $_ for
		q(),
		q([req_distinguished_name]);
	
	foreach (qw(C ST L O CN))
	{
		next unless (defined $subject{$_} and length $subject{$_});
		say $config "$_ = ", $subject{$_};
	}
	
	close $config;
	
	system(
		$openssl,
      "req",
      "-newkey"  => "rsa:".$key_size,
      "-x509",
      "-days"    => $days,
      "-config"  => $tempdir->file('openssl.cnf'),
      "-out"     => $tempdir->file('cert.pem'),
      "-keyout"  => $tempdir->file('privkey.pem'),
      "-passout" => "pass:".$passphrase,
		);

   system(
		$openssl,
      "pkcs12",
      "-export",
      "-in"      => $tempdir->file('cert.pem'),
      "-inkey"   => $tempdir->file('privkey.pem'),
      "-out"     => $tempdir->file('cert.p12'),
      "-name"    => sprintf('%s <%s>', ($subject{CN}//'Unnamed'), $sans->[0]->value), 
      "-passin"  => "pass:".$passphrase,
      "-passout" => "pass:".$passphrase,
		);
	
	if (ref $dest eq 'SCALAR')
	{
		$$dest = $tempdir->file('cert.p12')->slurp;
	}
	elsif (ref $dest =~ m/^IO/)
	{
		my $p12 = $tempdir->file('cert.p12')->slurp;
		print $dest $p12;
	}
	else
	{
		my $p12 = $tempdir->file('cert.p12')->slurp;
		my $fh  = Path::Class::File->new($dest)->openw;
		print $fh $p12;
	}
	
	my ($on_triple, $on_done) = (sub {}, sub {});
	if (ref $rdf_sink eq 'SCALAR')
	{
		$$rdf_sink = RDF::Trine::Model->new;
		$on_triple = sub { $$rdf_sink->add_statement(statement(@_)) };
	}
	elsif (blessed($rdf_sink) and $rdf_sink->isa('RDF::Trine::Model'))
	{
		$on_triple = sub { $rdf_sink->add_statement(statement(@_)) };
	}
	else
	{
		my $model = RDF::Trine::Model->new;
		$on_triple = sub { $model->add_statement(statement(@_)) };
		$on_done   = sub { RDF::Trine::Serializer->new('RDFXML')->serialize_model_to_file($rdf_sink, $model) };
	}

	my $pem  = $tempdir->file('cert.pem')->slurp;
	my $cert = $class->new(pem => $pem);

	my $k = blank();
	$on_triple->($k, u('rdf:type'), u('cert:RSAPublicKey'));
	$on_triple->($k, u('cert:modulus'), literal($cert->modulus, undef, uu('xsd:hexBinary')));
	$on_triple->($k, u('cert:exponent'), literal($cert->public_exponent, undef, uu('xsd:integer')));
	foreach my $san (@$sans)
	{
		next unless $san->type eq 'uniformResourceIdentifier';
		$on_triple->(iri($san->value), u('cert:key'), $k);
	}
	$on_done->();
	
	$tempdir->rmtree;

	return $cert;
}

__PACKAGE__
__END__

=head1 NAME

Web::Id::Certificate::Generator - role for Web::Id::Certificate

=head1 SYNOPSIS

 my $cert = Web::Id::Certificate->generate(%options);

=head1 DESCRIPTION

This is a role consumed by L<Web::Id::Certificate>. It could be
inlined in the class, but I was trying to avoid tainting it with
the horror that's found in this role.

=head2 Constructor

=over

=item C<< generator(%options) >>

Generates a brand new WebID-enabled certificate.

=back

=head2 Options

The following options can be passed to C<generator>

=over

=item * C<cert_output>

A passphrase-protected PKCS12 certificate file is generated as part of
the certificate generation process. The PKCS12 file is what you'd
typically import into a browser.

You can pass a scalar reference, in which case the PKCS12 data will be
written to that scalar; or a file handle or string file name.

This is a required option.

=item * C<passphrase>

The password for the PKCS12 file.

This is a required option.

=item * C<rdf_output>

RDF data is also generated as part of the certificate generation
process.

Again a file handle or string file name can be passed, or an
L<RDF::Trine::Model>.

This is a required option.

=item * C<subject_alt_names>

List of L<Web::Id::SAN> objects to generate the certificate's
subjectAltNames field. You want at least one L<Web::Id::SAN::URI>
in there.

This is a required option.

=item * C<subject_name>

The name of the person who will hold the certificate. (e.g. "Alice
Smith".)

This is a required option.

=item * C<subject_org>

The certificate holder's organisation.

Not required.

=item * C<subject_locality>

The locality (e.g. city) of the certificate holder's address.

Not required.

=item * C<subject_region>

The region (e.g. state or county) of the certificate holder's address.

Not required.

=item * C<subject_country>

Two letter ISO code for the country of the certificate holder's address.

Not required.

=item * C<openssl_path>

The path to the OpenSSL binary. Yes that's right, this role calls the
OpenSSL binary via C<system> calls. Defaults to "/usr/bin/openssl" (or
"c:\openssl\bin\openssl.exe" on Windows).

=item * C<key_size>

Key size in bits. Defaults to 1024. Bigger keys are more secure. Keys
bigger than 2048 bits will take a ridiculously long time to generate.
Keys less than 512 bits are pretty poor.

=item * C<not_after>

Date when the certificate should expire, as a L<DateTime> object.
Defaults to 365 days.

=back

	my $dest       = (delete $options{cert_output})
		or confess "need to provide cert_output option";
	my $rdf_sink   = (delete $options{rdf_output})
		or confess "need to provide rdf_output option";
	
	my %subject = (
		C    => delete $options{subject_country},
		ST   => delete $options{subject_region},
		L    => delete $options{subject_locality},
		O    => delete $options{subject_org},
		CN   => delete $options{subject_cn},
		);

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-Id>.

=head1 SEE ALSO

L<Web::Id::Certificate>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

