use Test::More;
use Test::Pod::Coverage;

my @modules =
	map { s[^lib/][]; s[.pm$][]; s[/][::]g; $_ }
	my @_x = qw(
		lib/Plack/Middleware/Auth/WebID.pm
		lib/Web/ID/Certificate/Generator.pm
		lib/Web/ID/Certificate.pm
		lib/Web/ID.pm
		lib/Web/ID/RSAKey.pm
		lib/Web/ID/SAN/Email.pm
		lib/Web/ID/SAN.pm
		lib/Web/ID/SAN/URI.pm
		lib/Web/ID/Types.pm
		lib/Web/ID/Util.pm
	);
pod_coverage_ok($_, "$_ is covered")
	foreach @modules;
done_testing(scalar @modules);

