package Web::Id::Certificate;

use 5.010;
use utf8;

BEGIN {
	$Web::Id::Certificate::AUTHORITY = 'cpan:TOBYINK';
	$Web::Id::Certificate::VERSION   = '0.001';
}

use Crypt::X509 0.50 ();  # why in the hell does this export anything?!
use DateTime 0;
use List::MoreUtils 0 qw(part);
use MIME::Base64 0 ();
use Web::Id::SAN;
use Web::Id::SAN::Email;
use Web::Id::SAN::URI;
use Web::Id::Util;

use Any::Moose;
with 'Web::Id::RSA';

TYPE_CONSTRAINTS:
{
	use Any::Moose 'Util::TypeConstraints';
	use constant +{qw{
		Str         Str
		Num         Num
		Datetime    Datetime
		ArrayRef    ArrayRef
		CodeRef     CodeRef
	}};

	# Datetime
	class_type Datetime,	{ class => 'DateTime' };
	coerce Datetime,
		from Num => via { DateTime->from_epoch(epoch => $_) };
}

has pem => (
	is          => read_only,
	isa         => Str,
	required    => true,
	coerce      => false,
	);

has _x509 => (
	is          => read_only,
	isa         => 'Crypt::X509',
	lazy_build  => true,
	);

has _rsa => (
	is          => read_only,
	lazy_build  => true,
	);

has subject_alt_names => (
	is          => read_only,
	isa         => ArrayRef,
	lazy_build  => true,
	);

has $_ => (
	is          => read_only,
	isa         => Datetime,
	lazy_build  => true,
	coerce      => true,
	)
	for qw( not_before not_after );

has san_factory => (
	is          => read_only,
	isa         => CodeRef,
	lazy_build  => true,
	);

sub _build__x509
{
	my ($self) = @_;
	
	my @lines = split /\n/, $self->pem;
	my $der   = MIME::Base64::decode_base64(
		join "\n", grep { !/--(BEGIN|END) CERTIFICATE--/ } @lines
		);

	return Crypt::X509->new(cert => $der);
}

sub _build__rsa
{
	my ($self) = @_;
	return $self->_x509->pubkey_components;
}

sub _build_public_exponent
{
	my ($self) = @_;
	return Math::BigInt->new($self->_rsa->{exponent});
}

sub _build_modulus
{
	my ($self) = @_;
	return Math::BigInt->new($self->_rsa->{modulus});
}

sub _build_subject_alt_names
{
	my ($self) = @_;
	my $factory = $self->san_factory;

	[_sort_san(
		map {
			my ($type, $value) = split /=/, $_, 2;
			$factory->(type => $type, value => $value);
		}
		@{ $self->_x509->SubjectAltName }
	)];
}

sub _build_not_before
{
	my ($self) = @_;
	return $self->_x509->not_before;
}

sub _build_not_after
{
	my ($self) = @_;
	return $self->_x509->not_after;
}

my $default_san_factory = sub
{
	my (%args) = @_;
	my $class = {
			uniformResourceIdentifier  => 'Web::Id::SAN::URI',
			rfc822Name                 => 'Web::Id::SAN::Email',
		}->{ $args{type} }
		// 'Web::Id::SAN';
	$class->new(%args);
};

sub _build_san_factory
{
	return $default_san_factory;
}

sub timely
{
	my ($self, $now) = @_;
	$now //= DateTime->now;
	
	return if $now > $self->not_after;
	return if $now < $self->not_before;
	
	return $self;
}

# Partly sorts a list of Web::Id::SAN objects,
# prioritising URIs and Email addresses.
sub _sort_san
{
	map  { ref($_) eq 'ARRAY' ? (@$_) : () }
	part {
		if ($_->isa('Web::Id::SAN::URI'))       { 0 }
		elsif ($_->isa('Web::Id::SAN::Email'))  { 1 }
		else                                    { 2 }
	}
	@_;
}

__PACKAGE__
