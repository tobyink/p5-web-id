package Web::Id::RSAKey;

use 5.010;
use utf8;

BEGIN {
	$Web::Id::RSAKey::AUTHORITY = 'cpan:TOBYINK';
	$Web::Id::RSAKey::VERSION   = '0.001';
}

use Any::Moose;
with 'Web::Id::RSA';

sub _build_modulus
{
	confess "modulus cannot be defaulted in Web::Id::RSAKey"
}

sub _build_public_exponent
{
	confess "public_exponent cannot be defaulted in Web::Id::RSAKey"
}

__PACKAGE__
