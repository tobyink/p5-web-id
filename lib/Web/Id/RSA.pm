package Web::Id::RSA;

use 5.010;
use utf8;

BEGIN {
	$Web::Id::RSA::AUTHORITY = 'cpan:TOBYINK';
	$Web::Id::RSA::VERSION   = '0.001';
}

use Web::Id::Util;

use Any::Moose 'Role';

TYPE_CONSTRAINTS:
{
	use Any::Moose 'Util::TypeConstraints';
	use constant +{qw{
		Str         Str
		Bigint      Bigint
	}};
	
	# Bigint
	class_type Bigint, { class => 'Math::BigInt' };
	coerce Bigint,
		from Str => via { Math::BigInt->new($_) };
}

for (qw( public_exponent modulus ))
{
	has $_ => (
		is          => read_only,
		isa         => Bigint,
		lazy_build  => true,
		coerce      => true,
		);
	requires '_build_'.$_;
}

sub rsa_equal
{
	my ($self, $other) = @_;
	
	return unless $self->does(__PACKAGE__);
	return unless $other->does(__PACKAGE__);
	return unless $self->modulus == $other->modulus;
	return unless $self->public_exponent == $other->public_exponent;
	
	return true;
}


__PACKAGE__
