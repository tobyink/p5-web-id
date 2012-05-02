package Web::Id::SAN;

use 5.010;
use utf8;

BEGIN {
	$Web::Id::SAN::AUTHORITY = 'cpan:TOBYINK';
	$Web::Id::SAN::VERSION   = '0.001';
}

use Any::Moose 'X::Types::Moose' => [':all'];
use Web::Id::Types ':all';
use RDF::Query 2.900;
use URI 0;
use URI::Escape 0 qw/uri_escape/;
use Web::Id::RSAKey;
use Web::Id::Util;

use Any::Moose;

has $_ => (
	is          => read_only,
	isa         => Str,
	required    => true,
	coerce      => false,
	)
	for qw(type value);

has model => (
	is          => read_only,
	isa         => Model,
	lazy_build  => true,
	);

has key_factory => (
	is          => read_only,
	isa         => CodeRef,
	lazy_build  => true,
	);

sub _build_model
{
	return RDF::Trine::Model->new;
}

my $default_key_factory = sub
{
	my (%args) = @_;
	return unless $args{exponent};
	return unless $args{modulus};
	Web::Id::RSAKey->new(%args);
};

sub _build_key_factory
{
	return $default_key_factory;
}

sub uri_object
{
	my ($self) = @_;
	return URI->new(sprintf 'urn:x-subject-alt-name:%s:%s', map {uri_escape $_} $self->type, $self->value);
}

sub to_string
{
	my ($self) = @_;
	sprintf('%s=%s', $self->type, $self->value);
}

sub associated_keys
{
	return;
}

__PACKAGE__
__END__

=head1 NAME

Web::Id::SAN - represents a single name from a certificate's subjectAltName field

=head1 DESCRIPTION

=head2 Constructor

=over

=item C<< new >>

Standard Moose-style constructor. (This class uses L<Any::Moose>.)

=back

=head2 Attributes

=over

=item C<< type >>

Something like 'uniformResourceIdentifier' or 'rfc822Name'. A string.

=item C<< value >>

The name itself. A string.

=item C<< model >>

An RDF::Trine::Model representing data about the subject identified by
this name.

To be useful, the C<model> needs to be buildable automatically given
C<type> and C<value>.

=item C<< key_factory >>

This is similar to the C<san_factory> found in L<Web::Id::Certificate>.
It's a coderef used to construct L<Web::Id::RSAKey> objects.

=back

=head2 Methods

=over

=item C<< uri_object >>

Forces the name to take the form of a URI identifying the subject. It's
not always an especially interesting URI.

=item C<< to_string >>

A printable form of the name. Not always very pretty.

=item C<< associated_keys >>

Finds RSA keys associated with this name in C<model>, and returns them as
a list of L<Web::Id::RSAKey> objects.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-Id>.

=head1 SEE ALSO

L<Web::Id>.

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

