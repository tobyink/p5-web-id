use 5.010;
use strict;

use lib 'lib';
use lib 't/lib';

use Test::More;
use Web::Id;
use Web::Id::Certificate::Generator;

-x '/usr/bin/openssl'
	or plan skip_all => "/usr/bin/openssl not executable";

our @PEOPLE = qw(alice bob carol david eve);
our %Certificates;

sub tmpfile
{
	my $file     = (shift // '');
	(my $tmpfile = __FILE__)
		=~ s{ 04webid.t }{ 'tmp/'.$file }ex;
	return $tmpfile;
}

{
	package Test::HTTP::Server::Request;
	no strict 'refs';
	for my $p (@::PEOPLE)
	{
		*$p = sub {
			shift->{out_headers}{content_type} =
				$p eq 'david' ? 'text/turtle' : 'application/rdf+xml';
			local $/ = undef;
			open my $fh, '<', main::tmpfile($p);
			<$fh>;
		}
	}
}

eval { require Test::HTTP::Server; 1; }
        or plan skip_all => "Could not use Test::HTTP::Server: $@";

plan tests => 12;
		  
my $server  = Test::HTTP::Server->new();
my $baseuri = $server->uri;

mkdir tmpfile();

for my $p (@PEOPLE)
{
	my $discard;
	my $rdf;
	$Certificates{$p} = 'Web::Id::Certificate'->generate(
		passphrase        => 'secret',
		subject_alt_names => [
			Web::Id::SAN::URI->new(value => $baseuri.$p),
		],
		subject_cn        => ucfirst($p),
		rdf_output        => \$rdf,
		cert_output       => \$discard,
	)->pem;
	
	isa_ok($rdf, 'RDF::Trine::Model', tmpfile($p).' $rdf');
	
	open my $fh, '>', tmpfile($p);
	RDF::Trine::Serializer
		-> new($p eq 'david' ? 'Turtle' : 'RDFXML')
		-> serialize_model_to_file($fh, $rdf);
}

for my $p (@PEOPLE)
{
	my $webid = Web::Id->new(certificate => $Certificates{$p});
	ok($webid->valid, $webid->uri);
}

unlink tmpfile('carol');  # bye, bye

my $carol = Web::Id->new(certificate => $Certificates{carol});
ok(!$carol->valid, 'bye, bye carol!');

do {
	my $data = do { local(@ARGV, $/) = tmpfile('eve'); <> };
	$data =~ s/exponent/component/g;
	
	open my $fh, '>', tmpfile('eve');
	print $fh $data;
};

my $eve = Web::Id->new(certificate => $Certificates{eve});
ok(!$eve->valid, 'eve is evil!');

for (@PEOPLE)
{
	1 while unlink tmpfile($_);
}

rmdir tmpfile();
