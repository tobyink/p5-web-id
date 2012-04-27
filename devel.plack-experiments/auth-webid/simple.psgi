use lib '/home/tai/perl5/hg/p5-web-id/lib';

use Plack::Builder;
use Data::Dumper;

my $app = sub
{
	local $Data::Dumper::Terse = 1;
	
	my $env     = shift;
	my $headers = ['Content-Type' => 'text/plain'];
	my $body    = [Dumper($env)];
	
	return [200, $headers, $body];
};

builder
{
	enable "Auth::WebId";
	$app;
};

