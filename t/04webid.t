use 5.010;
use strict;

use lib 'lib';
use lib 't/lib';

use File::Temp qw();
use Path::Class qw();
use Test::More;
use Web::ID;
use Web::ID::Certificate::Generator;

-x '/usr/bin/openssl'
	or plan skip_all => "/usr/bin/openssl not executable";

our @PEOPLE = qw(alice bob carol david eve);
our %Certificates;

my $tmpdir = Path::Class::Dir->new( File::Temp->newdir );
$tmpdir->mkpath;

sub tmpfile
{
	return $tmpdir->file(@_) if @_;
	return $tmpdir;
}

{
	package Test::HTTP::Server::Request;
	no strict 'refs';
	for my $p (@::PEOPLE)
	{
		*$p = sub {
			if (-e main::tmpfile($p))
			{
				shift->{out_headers}{content_type} =
					$p eq 'david' ? 'text/turtle' : 'application/rdf+xml';
				~~main::tmpfile($p)->slurp;
			}
			else
			{
				my $server = shift;
				$server->{out_code} = '404 Not Found';
				$server->{out_headers}{content_type} = 'text/plain';
				'Not Found';
			}
		}
	}
}

eval { require Test::HTTP::Server; 1; }
        or plan skip_all => "Could not use Test::HTTP::Server: $@";

plan tests => 12;
		  
my $server  = Test::HTTP::Server->new();
my $baseuri = $server->uri;

for my $p (@PEOPLE)
{
	my $discard;
	my $rdf;
	$Certificates{$p} = 'Web::ID::Certificate'->generate(
		passphrase        => 'secret',
		subject_alt_names => [
			Web::ID::SAN::URI->new(value => $baseuri.$p),
		],
		subject_cn        => ucfirst($p),
		rdf_output        => \$rdf,
		cert_output       => \$discard,
	)->pem;
	
	isa_ok($rdf, 'RDF::Trine::Model', tmpfile($p).' $rdf');
	
	RDF::Trine::Serializer
		-> new($p eq 'david' ? 'Turtle' : 'RDFXML')
		-> serialize_model_to_file(tmpfile($p)->openw, $rdf);
}

for my $p (@PEOPLE)
{
	my $webid = Web::ID->new(certificate => $Certificates{$p});
	ok($webid->valid, $webid->uri);
}

tmpfile('carol')->remove;  # bye, bye

my $carol = Web::ID->new(certificate => $Certificates{carol});
ok(!$carol->valid, 'bye, bye carol!');

do {
	(my $data = tmpfile('eve')->slurp)
		=~ s/exponent/component/g;
	my $fh = tmpfile('eve')->openw;
	print $fh $data;
};

my $eve = Web::ID->new(certificate => $Certificates{eve});
ok(!$eve->valid, 'eve is evil!');

tmpfile()->rmtree;
