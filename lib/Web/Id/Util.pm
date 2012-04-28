package Web::Id::Util;

use 5.010;
use strict;
use utf8;

use Carp qw/confess/;
use Math::BigInt 0 try => 'GMP';
use RDF::Trine::NamespaceMap;

our (@EXPORT, @EXPORT_OK);
BEGIN {
	@EXPORT    = qw(make_bigint_from_node get_trine_model u uu
	                true false read_only read_write);
	@EXPORT_OK = (@EXPORT, qw());
}

use Sub::Exporter -setup => {
	exports => \@EXPORT_OK,
	groups  => {
		default  => \@EXPORT,
		all      => \@EXPORT_OK,
	},
};

use constant {
	read_only  => 'ro',
	read_write => 'rw',
};

use constant {
	true  => !!1, 
	false => !!0,
};

sub u (;$)
{
	state $namespaces //= RDF::Trine::NamespaceMap->new({
		rdf	=> 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
		rdfs	=> 'http://www.w3.org/2000/01/rdf-schema#',
		owl	=> 'http://www.w3.org/2002/07/owl#',
		xsd	=> 'http://www.w3.org/2001/XMLSchema#',
		foaf	=> 'http://xmlns.com/foaf/0.1/',
		cert	=> 'http://www.w3.org/ns/auth/cert#',
		rsa	=> 'http://www.w3.org/ns/auth/rsa#',
	});
	
	if (@_)
	{
		my $rv = $namespaces->uri(@_)
			or confess "couldn't expand term $_[0]";
		return $rv;
	}
	
	return $namespaces;
}

sub uu ($)
{
	return u(shift)->uri;
}

sub get_trine_model
{
	my ($uri, $model) = @_;
	
	$model //= RDF::Trine::Model->new;
	RDF::Trine::Parser->parse_url_into_model($uri, $model);
	
	return $model;
}

sub make_bigint_from_node
{
	my ($node, %opts) = @_;
	
	state $test_hex = uu('cert:hex');
	
	state $test_unsigned = [
		uu('cert:decimal'),
		uu('cert:int'),
		qr{^
			http://www.w3.org/2001/XMLSchema#
			(?:
				unsigned(?:Long|Int|Short|Byte)
				|positiveInteger
				|nonNegitiveInteger
			)
		$}x
	];
	
	state $test_signed = qr{^
		http://www.w3.org/2001/XMLSchema#
		(?:
			integer
			|negitiveInteger
			|nonPositiveInteger
			|long
			|short
			|int
			|byte
		)
	$}x;
	
	state $test_decimal = uu('xsd:decimal');
		
	if ($node->is_literal)
	{
		given ($node->literal_datatype)
		{
			when ($_ ~~ $test_hex)
			{
				( my $hex = $node->literal_value ) =~ s/[^0-9A-F]//ig;
				return Math::BigInt->from_hex("0x$hex");
			}
			
			when ($_ ~~ $test_unsigned)
			{
				( my $dec = $node->literal_value ) =~ s/[^0-9]//ig;
				return Math::BigInt->new("$dec");
			}
			
			when ($_ ~~ $test_signed)
			{
				( my $dec = $node->literal_value ) =~ s/[^0-9-]//ig;
				return Math::BigInt->new("$dec");
			}
			
			when ($_ ~~ $test_decimal)
			{
				my ($dec, $frac) = split /\./, $node->literal_value, 2;
				warn "Ignoring fractional part of xsd:decimal number."
					if defined $frac;
				
				$dec =~ s/[^0-9-]//ig;
				return Math::BigInt->new("$dec");
			}
			
			when ($_ ~~ undef)
			{
				$opts{'fallback'} = $node;
			}
		}
	}
	
	if (defined( my $node = $opts{'fallback'} )
	and $opts{'fallback'}->is_literal)
	{
		if ($opts{'fallback_type'} eq 'hex')
		{
			warn "HEX FALLBACK";
			(my $hex = $node->literal_value) =~ s/[^0-9A-F]//ig;
			return Math::BigInt->from_hex("0x$hex");
		}
		else # dec
		{
			warn "DECIMAL FALLBACK";
			my ($dec, $frac) = split /\./, $node->literal_value, 2;
			warn "Ignoring fractional part of xsd:decimal number."
				if defined $frac;
				
			$dec =~ s/[^0-9]//ig;
			return Math::BigInt->new("$dec");			
		}
	}
	
	return;
}


__PACKAGE__
__END__

