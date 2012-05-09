package Web::ID::RSAKey;

use 5.010;
use utf8;

BEGIN {
	$Web::ID::RSAKey::AUTHORITY = 'cpan:TOBYINK';
	$Web::ID::RSAKey::VERSION   = '1.910_04';
}

use Any::Moose 'X::Types::Moose' => [':all'];
use Web::ID::Types ':all';
use Web::ID::Util;

use Any::Moose;
use namespace::clean -except => 'meta';

for (qw( exponent modulus ))
{
	has $_ => (
		is          => read_only,
		isa         => Bigint,
		required    => true,
		coerce      => true,
		);
}

sub rsa_equal
{
	my ($self, $other) = @_;
	
	foreach (qw(exponent modulus))
	{
		my $m1 = $self->can($_)  or return;
		my $m2 = $other->can($_) or return;
		return unless $self->$m1 == $other->$m2;
	}
	
	return true;
}

__PACKAGE__
__END__

=head1 NAME

Web::ID::RSAKey - an RSA key

=head1 DESCRIPTION

=head2 Constructor

=over

=item C<< new >>

Standard Moose-style constructor. (This class uses L<Any::Moose>.)

=back

=head2 Attributes

=over

=item C<< exponent >>

The exponent as a Math::BigInt object.

=item C<< modulus >>

The modulus as a Math::BigInt object.

=back

=head2 Methods

=over

=item C<< rsa_equal($that) >>

Returns true iff this key is the same as that key.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-ID>.

=head1 SEE ALSO

L<Web::ID>, L<Web::ID::Certificate>.

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

