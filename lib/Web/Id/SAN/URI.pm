package Web::Id::SAN::URI;

use 5.010;
use utf8;

BEGIN {
	$Web::Id::SAN::URI::AUTHORITY = 'cpan:TOBYINK';
	$Web::Id::SAN::URI::VERSION   = '0.001';
}

use Any::Moose 'X::Types::Moose' => [':all'];
use Web::Id::Types ':all';
use Web::Id::Util;

use Any::Moose;
extends 'Web::Id::SAN';

override uri_object => sub
{
	my ($self) = @_;
	return URI->new($self->value);
};

around _build_model => sub
{
	my ($orig, $self) = @_;
	my $model = $self->$orig;
	return get_trine_model($self->value => $model);
};

around associated_keys => sub
{
	my ($orig, $self) = @_;
	my @keys = $self->$orig;
	
	my $results = $self->query->execute( $self->model );
	RESULT: while (my $result = $results->next)
	{
		# trim any whitespace around modulus
		# (HACK for MyProfile WebIDs)
		# Should probably be in ::Util.
		$result->{modulus}->[0] =~ s/(^\s+)|(\s+$)//g;
		
		my $modulus = make_bigint_from_node(
			$result->{modulus},
			fallback      => $result->{hexModulus},
			fallback_type =>'hex',
			);
		my $public_exponent = make_bigint_from_node(
			$result->{exponent},
			fallback      => $result->{decExponent},
			fallback_type =>'dec',
			);
		
		push @keys, $self->key_factory->(
			modulus         => $modulus,
			public_exponent => $public_exponent,
			);
	}
	
	return @keys;
};

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

