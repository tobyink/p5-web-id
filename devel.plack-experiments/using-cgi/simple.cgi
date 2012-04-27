#!/usr/bin/perl
use Plack::Loader;
my $app = Plack::Util::load_psgi("../simple/simple.psgi");
Plack::Loader->auto->run($app);
