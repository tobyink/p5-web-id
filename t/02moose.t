use Test::More;
eval { require Moose; require MooseX::Types::Moose; 1 }
	or plan skip_all => "need Moose";

plan tests => 1;
use_ok('Web::ID');

