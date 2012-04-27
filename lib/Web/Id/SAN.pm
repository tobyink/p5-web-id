package Web::Id::SAN;

use 5.010;
use utf8;

BEGIN {
	$Web::Id::SAN::AUTHORITY = 'cpan:TOBYINK';
	$Web::Id::SAN::VERSION   = '0.001';
}

use Web::Id::RSAKey;
use Web::Id::Util;

use Any::Moose;

TYPE_CONSTRAINTS:
{
	use Any::Moose 'Util::TypeConstraints';
	use constant +{qw{
		Model       Model
		Str         Str
		CodeRef     CodeRef
	}};
	
	# Model
	class_type Model, { class => 'RDF::Trine::Model' };
}

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
	coerce      => true,
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
	Web::Id::RSAKey->new(%args);
};

sub _build_key_factory
{
	return $default_key_factory;
}

sub associated_keys
{
	return;
}

sub uri_object
{
	return URI->new('urn:x-rand:'.rand(100_000_000));
}

sub to_string
{
	my ($self) = @_;
	sprintf('%s=%s', $self->type, $self->value);
}

sub query
{
	my ($self) = @_;
	return RDF::Query->new( sprintf(<<'SPARQL', (($self->uri_object)x4)) );
PREFIX cert: <http://www.w3.org/ns/auth/cert#>
PREFIX rsa: <http://www.w3.org/ns/auth/rsa#>
SELECT
	?modulus
	?exponent
	?decExponent
	?hexModulus
WHERE
{
	{
		?key
			cert:identity <%s> ;
			rsa:modulus ?modulus ;
			rsa:public_exponent ?exponent .
	}
	UNION
	{
		<%s> cert:key ?key .
		?key
			rsa:modulus ?modulus ;
			rsa:public_exponent ?exponent .
	}
	UNION
	{
		?key
			cert:identity <%s> ;
			cert:modulus ?modulus ;
			cert:exponent ?exponent .
	}
	UNION
	{
		<%s> cert:key ?key .
		?key
			cert:modulus ?modulus ;
			cert:exponent ?exponent .
	}
	OPTIONAL { ?modulus cert:hex ?hexModulus . }
	OPTIONAL { ?exponent cert:decimal ?decExponent . }
}
SPARQL
}

__PACKAGE__

