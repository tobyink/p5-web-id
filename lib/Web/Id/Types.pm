package Web::Id::Types;

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
		
class_type Certificate, { class => 'Web::Id::Certificate' };
coerce Certificate,
	from HashRef, via  { Web::Id::Certificate->new(%$_) },
	from Str,     via  { Web::Id::Certificate->new(pem => $_) };

class_type Datetime,	{ class => 'DateTime' };
coerce Datetime,
	from Num, via { DateTime->from_epoch(epoch => $_) };

class_type Finger, { class => 'WWW::Finger' };
coerce Finger,
	from Str, via { WWW::Finger->new($_) if UNIVERSAL::can('WWW::Finger', 'new') };

class_type Model, { class => 'RDF::Trine::Model' };

class_type Rsakey, { class => 'Web::Id::RSAKey' };
coerce Rsakey,
	from HashRef, via  { Web::Id::RSAKey->new(%$_) };

class_type San, { class => 'Web::Id::SAN' };

class_type Uri, { class => 'URI' };
coerce Uri,
	from Str, via { URI->new($_) };


__PACKAGE__
