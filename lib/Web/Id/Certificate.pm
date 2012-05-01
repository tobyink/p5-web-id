package Web::Id::Certificate;

use 5.010;
use utf8;

BEGIN {
	$Web::Id::Certificate::AUTHORITY = 'cpan:TOBYINK';
	$Web::Id::Certificate::VERSION   = '0.001';
}

use Crypt::X509 0.50 ();  # why the hell does this export anything?!
use Digest::SHA1 'sha1_hex';
use DateTime 0;
use List::MoreUtils 0 qw(part);
use MIME::Base64 0 ();
use Any::Moose 'X::Types::Moose' => [':all'];
use Web::Id::Types ':all';
use Web::Id::SAN;
use Web::Id::SAN::Email;
use Web::Id::SAN::URI;
use Web::Id::Util;

use Any::Moose;

has pem => (
	is          => read_only,
	isa         => Str,
	required    => true,
	coerce      => false,
	);

has _der => (
	is          => read_only,
	isa         => Str,
	required    => true,
	lazy_build  => true,
	);

has _x509 => (
	is          => read_only,
	isa         => 'Crypt::X509',
	lazy_build  => true,
	);

has public_key => (
	is          => read_only,
	isa         => Rsakey,
	lazy_build  => true,
	handles     => [qw(modulus exponent)],
	);

has subject_alt_names => (
	is          => read_only,
	isa         => ArrayRef,
	lazy_build  => true,
	);

has $_ => (
	is          => read_only,
	isa         => Datetime,
	lazy_build  => true,
	coerce      => true,
	)
	for qw( not_before not_after );

has san_factory => (
	is          => read_only,
	isa         => CodeRef,
	lazy_build  => true,
	);

has fingerprint => (
	is          => read_only,
	isa         => Str,
	lazy_build  => true,
	);

sub _build_fingerprint
{
	lc sha1_hex( shift->_der );
}

sub _build__der
{
	my @lines = split /\n/, shift->pem;
	MIME::Base64::decode_base64(
		join "\n", grep { !/--(BEGIN|END) CERTIFICATE--/ } @lines
		);
}

sub _build__x509
{
	return Crypt::X509->new(cert => shift->_der);
}

sub _build_public_key
{
	my ($self) = @_;
	Web::Id::RSAKey->new($self->_x509->pubkey_components);
}

sub _build_subject_alt_names
{
	my ($self) = @_;
	my $factory = $self->san_factory;

	[_sort_san(
		map {
			my ($type, $value) = split /=/, $_, 2;
			$factory->(type => $type, value => $value);
		}
		@{ $self->_x509->SubjectAltName }
	)];
}

sub _build_not_before
{
	my ($self) = @_;
	return $self->_x509->not_before;
}

sub _build_not_after
{
	my ($self) = @_;
	return $self->_x509->not_after;
}

my $default_san_factory = sub
{
	my (%args) = @_;
	my $class = {
			uniformResourceIdentifier  => 'Web::Id::SAN::URI',
			rfc822Name                 => 'Web::Id::SAN::Email',
		}->{ $args{type} }
		// 'Web::Id::SAN';
	$class->new(%args);
};

sub _build_san_factory
{
	return $default_san_factory;
}

sub timely
{
	my ($self, $now) = @_;
	$now //= DateTime->now;
	
	return if $now > $self->not_after;
	return if $now < $self->not_before;
	
	return $self;
}

# Partly sorts a list of Web::Id::SAN objects,
# prioritising URIs and Email addresses.
sub _sort_san
{
	map  { ref($_) eq 'ARRAY' ? (@$_) : () }
	part {
		if ($_->isa('Web::Id::SAN::URI'))       { 0 }
		elsif ($_->isa('Web::Id::SAN::Email'))  { 1 }
		else                                    { 2 }
	}
	@_;
}

__PACKAGE__
__END__

=head1 NAME

Web::Id::Certificate - an x509 certificate

=head1 SYNOPSIS

 my $cert = Web::Id::Certificate->new(pem => $pem_encoded_x509);
 foreach (@{ $cert->subject_alt_names })
 {
   say "SAN: ", $_->type, " = ", $_->value;
 }

=head1 DESCRIPTION

=head2 Constructor

=over

=item C<< new >>

Standard Moose-style constructor. (This class uses L<Any::Moose>.)

=back

=head2 Attributes

=over

=item C<< pem >>

A PEM-encoded string for the certificate.

This is usually the only attribute you want to pass to the constructor.
Allow the others to be built automatically.

=item C<< public_key >>

A L<Web::Id::RSAKey> object.

=item C<< fingerprint >>

A string identifier for the certificate. It is the lower-cased
hexadecimal SHA1 hash of the DER-encoded certificate.

This is not used in WebId authentication, but may be used as an
identifier for the certificate if you need to keep it in a cache.

=item C<< not_before >>

L<DateTime> object indicating when the certificate started (or will
start) to be valid.

=item C<< not_after >>

L<DateTime> object indicating when the certificate will cease (or
has ceased) to be valid.

=item C<< subject_alt_names >>

An arrayref containing a list of subject alt names (L<Web::Id::SAN>
objects) associated with the certificate. These are sorted in the order
they'll be tried for WebId authentication. 

=item C<< san_factory >>

A coderef used for building L<Web::Id::SAN> objects. It's very unlikely
you need to play with this - the default is probably OK. But changing this
is "supported" (in so much as any of this is supported).

The coderef is passed a hash (not hashref) along the lines of:

 (
   type  => 'uniformResourceIdentifier',
   value => 'http://example.com/id/alice',
 )

=back

=head2 Methods

=over

=item C<< timely >>

Checks C<not_before> and C<not_after> against the current system time to
indicate whether the certifixate is temporally valid. Returns a boolean.

You can optionally pass it a L<DateTime> object to use instead of the
current system time.

=item C<< exponent >>

Delegated to the C<public_key> attribute.

=item C<< modulus >>

Delegated to the C<public_key> attribute.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-Id>.

=head1 SEE ALSO

L<Web::Id>, L<Crypt::X509>.

L<Web::Id::Certificate::Generator> - augments this class to add the
ability to generate new WebId certificates.

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

