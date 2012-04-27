package Web::Id;

use 5.010;
use utf8;

BEGIN {
	$Web::Id::AUTHORITY = 'cpan:TOBYINK';
	$Web::Id::VERSION   = '0.001';
}

use Web::Id::Certificate;
use Web::Id::Util;

use Any::Moose;

TYPE_CONSTRAINTS:
{
	use Any::Moose 'Util::TypeConstraints';
	use constant +{qw{
		Model       Model
		Uri         Uri
		Cert        Cert
		Str         Str
		Bool        Bool
		San         San
	}};
	
	# Model
	class_type Model, { class => 'RDF::Trine::Model' };
	
	# URI
	class_type Uri, { class => 'URI' };
	coerce Uri,
		from Str => via { URI->new($_) };
		
	# Certificate
	class_type Cert, { class => 'Web::Id::Certificate' };
	coerce Cert,
		from Str => via  { Web::Id::Certificate->new(pem => $_) };

	# San
	class_type San, { class => 'Web::Id::SAN' };
}

has certificate => (
	is          => read_only,
	isa         => Cert,
	required    => true,
	coerce      => true,
	);

has uri => (
	is          => read_only,
	isa         => Uri,
	lazy_build  => true,
	coerce      => true,
	);

has profile => (
	is          => read_only,
	isa         => Model,
	lazy_build  => true,
	coerce      => true,
	);

has valid => (
	is          => read_only,
	isa         => Bool,
	lazy_build  => true,
	);

has first_valid_san => (
	is          => read_only,
	isa         => 'San|Undef',
	lazy_build  => true,
	);

sub _build_valid
{
	my ($self) = @_;
	return true if defined $self->first_valid_san;
	return false;
}

sub _build_uri
{
	my ($self) = @_;
	$self->first_valid_san->uri_object;
}

sub _build_profile
{
	my ($self) = @_;
	$self->first_valid_san->model;
}

sub _build_first_valid_san
{
	my ($self) = @_;
	my $cert   = $self->certificate;
	my @sans   = @{ $cert->subject_alt_names };
	
	foreach my $san (@sans)
	{
		foreach my $key ( $san->associated_keys )
		{
			return $san if $key->rsa_equal($cert);
		}
	}
	
	return undef;
}

sub node
{
	my ($self) = @_;
	RDF::Trine::Node::Resource->new($self->uri.'');
}

sub get
{
	my $self = shift;
	my @pred = map {
		if (blessed $_ and $_->isa('RDF::Trine::Node'))   {   $_ }
		else                                              { u $_ }
	} @_;
	
	my %results =
		map { $_ => 1 }
		map { $_->is_resource ? $_->uri : $_->literal_value }
		grep { $_->is_literal or $_->is_resource }
		$self->profile->objects_for_predicate_list($self->node, @pred);
	my @results = sort keys %results;
	
	wantarray ? @results : $results[0];
}

__PACKAGE__
__END__

=head1 NAME

Web::Id - implementation of WebId (a.k.a. FOAF+SSL)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-Id>.

=head1 SEE ALSO

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

