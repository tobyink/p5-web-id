use inc::Module::Package "RDF:tobyink 0.012";

use lib "lib";
require Web::ID::Util::FindOpenSSL;
dynamic_config;
requires "Alien::OpenSSL" => "0.03"
	unless -x Web::ID::Util::FindOpenSSL::find_openssl();
