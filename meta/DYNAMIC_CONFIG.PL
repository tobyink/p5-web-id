	# If we can't find openssl via normal techniques,
	# add a dependency on Alien::OpenSSL.
	#
	use lib "lib";
	require Web::ID::Util::FindOpenSSL;
	$meta->{prereqs}{runtime}{requires}{"Alien::OpenSSL"} = "0.03"
		unless -x Web::ID::Util::FindOpenSSL::find_openssl();
