use Web::Id::Certificate::Generator;

Web::Id::Certificate->generate(
	passphrase        => 'test1234',
	subject_alt_names => [
		Web::Id::SAN::URI->new(value => 'http://example.com/id/alice'),
		Web::Id::SAN::URI->new(value => 'http://example.net/id/alice'),
		],
	cert_output       => \(my $output),
	rdf_output        => \(my $model),
	subject_cn        => 'Alice Test',
	subject_country   => 'gb',
	);
	
print RDF::Trine::Serializer
	-> new('RDFXML')
	-> serialize_model_to_string($model);
