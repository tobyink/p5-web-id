use lib '/home/tai/perl5/hg/p5-web-id/lib';

use Cache::MemoryCache;
use Plack::Builder;
use Data::Dumper;

my $cache = Cache::MemoryCache->new({
	namespace          => 'WebID',
	default_expires_in => 600,
});

my $app = sub
{
	local $Data::Dumper::Terse    = 1;
	local $Data::Dumper::Sortkeys = 1;
	
	my $env     = shift;
	my $headers = ['Content-Type' => 'text/plain'];
	my $body    = [Dumper($env)];
	
	return [200, $headers, $body];
};

builder
{
	enable "Auth::WebID",
		cache            => $cache,
		no_object_please => 1;
	$app;
};

