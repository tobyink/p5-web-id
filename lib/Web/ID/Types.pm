package Web::ID::Types;

use 5.010;
use strict;
use utf8;

use DateTime;
use Math::BigInt;
use RDF::Trine;
use URI;

use Any::Moose
	'X::Types' => [
		-declare => [qw[ Bigint Certificate Datetime Finger Model Rsakey San Uri ]],
	],
	'X::Types::Moose' => [
		':all',
	];

class_type Bigint, { class => 'Math::BigInt' };
coerce Bigint,
	from Str, via { Math::BigInt->new($_) };
		
class_type Certificate, { class => 'Web::ID::Certificate' };
coerce Certificate,
	from HashRef, via  { Web::ID::Certificate->new(%$_) },
	from Str,     via  { Web::ID::Certificate->new(pem => $_) };

class_type Datetime,	{ class => 'DateTime' };
coerce Datetime,
	from Num, via { DateTime->from_epoch(epoch => $_) };

class_type Finger, { class => 'WWW::Finger' };
coerce Finger,
	from Str, via { WWW::Finger->new($_) if UNIVERSAL::can('WWW::Finger', 'new') };

class_type Model, { class => 'RDF::Trine::Model' };

class_type Rsakey, { class => 'Web::ID::RSAKey' };
coerce Rsakey,
	from HashRef, via  { Web::ID::RSAKey->new(%$_) };

class_type San, { class => 'Web::ID::SAN' };

class_type Uri, { class => 'URI' };
coerce Uri,
	from Str, via { URI->new($_) };


__PACKAGE__
__END__

=head1 NAME

Web::ID::Types - type library for Web::ID and friends

=head1 DESCRIPTION

This module uses L<Any::Moose> and is capable of providing either a
L<MooseX::Types> type library, or a L<MouseX::Types> type library.

=head2 Types

=over

=item * C<Bigint>

=item * C<Certificate>

=item * C<Datetime>

=item * C<Finger>

=item * C<Model>

=item * C<Rsakey>

=item * C<San>

=item * C<Uri>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-ID>.

=head1 SEE ALSO

L<Web::ID>.

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

