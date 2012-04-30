package Plack::Middleware::Auth::WebId;

use strict;
use base qw(Plack::Middleware);
use Class::Load qw(load_class);
use Plack::Util;
use Plack::Util::Accessor qw(
	webid_class
	certificate_env_key
	on_unauth
	no_object_please
);

my $default_unauth = sub
{
	my ($self, $env) = @_;
	$env->{WEBID}        = Plack::Util::FALSE;
	$env->{WEBID_OBJECT} = Plack::Util::FALSE;
	$self->app->($env);
};

sub prepare_app
{
	my ($self) = @_;
	
	$self->certificate_env_key('SSL_CLIENT_CERT')
		unless defined $self->certificate_env_key;
	
	$self->webid_class('Web::Id')
		unless defined $self->webid_class;
	
	$self->on_unauth($default_unauth)
		unless defined $self->on_unauth;
	
	load_class('Web::Id');
}

sub call
{
	my ($self, $env) = @_;
	my $unauth = $self->on_unauth;
	
	my $cert  = $env->{ $self->certificate_env_key }
		or return $self->$unauth($env);
	
	my $webid = $self->webid_class->new(certificate => $cert);
	
	if ($webid->valid)
	{
		$env->{WEBID}        = $webid->uri . '';
		$env->{WEBID_OBJECT} = $webid unless $self->no_object_please;
		
		return $self->app->($env);
	}
	
	return $self->$unauth($env);
}

__PACKAGE__
__END__

=head1 NAME

Plack::Middleware::Auth::WebId - authentication middleware for WebId

=head1 SYNOPSIS

  use Plack::Builder;
  my $app = sub { ... };

  sub unauthenticated
  {
      my ($self, $env) = @_;
      return [
        403,
        [ 'Content-Type' => 'text/plain' ],
        [ '403 Forbidden' ],
      ];
  }
  
  builder
  {
      enable "Auth::WebId", on_unauth => \&unauthenticated;
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::Auth::WebId is a WebId handler for Plack.

If authentication is successful, then the handler sets C<< $env->{WEBID} >>
to the user's WebId URI, and sets C<< $env->{WEBID_OBJECT} >> to a
L<Web::Id> object.

=begin private

=item call

=item prepare_app

=end private

=head1 CONFIGURATION

=over 4

=item on_unauth

Coderef that will be called if authentication is not successful. You
can use this to return a "403 Forbidden" page for example, or try an
alternative authentication method.

The default coderef used will simply run the application as normal,
but setting C<< $env->{WEBID} >> to the empty string.

=item webid_class

Name of an alternative class to use for WebId authentication instead
of L<Web::Id>. Note that any such class would need to provide a compatible
C<new> constructor.

=item certificate_env_key

The key within C<< $env >> where Plack::Middleware::Auth::WebId can find
a PEM-encoded client SSL certificate.

Apache keeps this information in C<< $env->{'SSL_CLIENT_CERT'} >>, so
it should be no surprise that this setting defaults to 'SSL_CLIENT_CERT'.

=item no_object_please

Suppresses setting C<< $env->{WEBID_OBJECT} >>. C<< $env->{WEBID} >> will
still be set as usual.

=back

=head1 SERVER SUPPORT

WebId is an authentication system based on the Semantic Web and HTTPS.
It relies on client certificates (but not on certification authorities;
self-signed certificates are OK).

So for this authentication module to work...

=over

=item * You need to be using a server which supports HTTPS.

Many web PSGI web servers (e.g. HTTP::Server::Simple, Starman, etc) do
not support HTTPS. In some cases these are used with an HTTPS proxy in
front of them.

=item * Your HTTPS server needs to request a client certificate from the client.

If you're using Apache (via CGI or mod_perl) then you want to look at the
B<SSLVerifyClient> directive.

=item * Your HTTPS server needs to expose the client certificate to Plack via C<< $env >>.

If you're using Apache, then you want to set the B<SSLOptions>
directive and enable the C<ExportCertData> option, or try
L<Plack::Middleware::Apache2::ModSSL>.

If you're using an HTTPS proxy in front of a non-HTTPS web server,
then you might need to be creative to find a way to forward this
information to your backend web server.

=item * The client browser needs to have a WebId-compatible certificate installed.

Nuff said.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Web-Id>.

=head1 SEE ALSO

L<Plack>, L<Web::Id>.

L<http://webid.info/>,
L<http://www.w3.org/wiki/WebID>,
L<http://www.w3.org/2005/Incubator/webid/spec/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

