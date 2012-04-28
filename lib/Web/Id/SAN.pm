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

