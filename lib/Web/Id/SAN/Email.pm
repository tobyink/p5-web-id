package Web::Id::SAN::Email;

use 5.010;
use utf8;

our $WWW_Finger = 0;

BEGIN {
	$Web::Id::Email::URI::AUTHORITY = 'cpan:TOBYINK';
	$Web::Id::Email::URI::VERSION   = '0.001';
	
	eval {
		require WWW::Finger;
		WWW::Finger->VERSION('0.100');
		$WWW_Finger++;
	}
}

use Any::Moose 'X::Types::Moose' => [':all'];
use Web::Id::Types ':all';
use Web::Id::Util;

use Any::Moose;
extends 'Web::Id::SAN';

has finger => (
	is          => read_only,
	isa         => Finger | Undef,
	lazy        => true,
	builder     => '_build_finger',
	);

sub _build_finger
{
	my ($self) = @_;
	return WWW::Finger->new($self->value);
}

around _build_model => sub
{
	my ($orig, $self) = @_;
	
	if (my $finger = $self->finger)
	{
		if ($finger->endpoint)
		{
			my $store = RDF::Trine::Store::SPARQL->new($finger->endpoint);
			return RDF::Trine::Model->new($store);
		}
		return $finger->graph;
	}
	
	$self->$orig();
};

around associated_keys => sub
{
	my ($orig, $self) = @_;
	my @keys = $self->$orig;
	
	my $results = $self->query->execute( $self->model );
	RESULT: while (my $result = $results->next)
	{
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
	my $email = 'mailto:' . $self->value;
	return RDF::Query->new( sprintf(<<'SPARQL', (($email)x4)) );
PREFIX cert: <http://www.w3.org/ns/auth/cert#>
PREFIX rsa: <http://www.w3.org/ns/auth/rsa#>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT
	?webid
	?modulus
	?exponent
	?decExponent
	?hexModulus
WHERE
{
	{
		?webid foaf:mbox <%s> .
		?key
			cert:identity ?webid ;
			rsa:modulus ?modulus ;
			rsa:public_exponent ?exponent .
	}
	UNION
	{
		?webid
			foaf:mbox <%s> ;
			cert:key ?key .
		?key
			rsa:modulus ?modulus ;
			rsa:public_exponent ?exponent .
	}
	UNION
	{
		?webid foaf:mbox <%s> .
		?key
			cert:identity ?webid ;
			cert:modulus ?modulus ;
			cert:exponent ?exponent .
	}
	UNION
	{
		?webid
			foaf:mbox <%s> ;
			cert:key ?key .
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

