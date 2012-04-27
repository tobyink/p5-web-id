use Data::Dumper;

my $app = sub
{
	local $Data::Dumper::Terse = 1;
	
	my $env     = shift;
	my $headers = ['Content-Type' => 'text/plain'];
	my $body    = [Dumper($env)];
	
	return [200, $headers, $body];
};
