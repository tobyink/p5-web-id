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

my $auth = sub
{
	my ($username, $password) = @_;
	return $username eq 'admin' && $password eq 's3cr3t';
};

builder
{
	enable "Auth::Basic", authenticator => $auth;
	$app;
};