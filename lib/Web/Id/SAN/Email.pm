package Web::Id::SAN::Email;

use 5.010;
use utf8;

BEGIN {
	$Web::Id::Email::URI::AUTHORITY = 'cpan:TOBYINK';
	$Web::Id::Email::URI::VERSION   = '0.001';
}

use Web::Id::Util;

use Any::Moose;
extends 'Web::Id::SAN';

__PACKAGE__

