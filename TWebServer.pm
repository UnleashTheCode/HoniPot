package TWebServer;
use strict;
use warnings;


use CGI;
use NetAddr::IP;

{
package Server;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);

my @values;

my %dispatch = (
    '/hello' => \&resp_hello,
    # ...
);
 
sub handle_request {
    my $self = shift;
    my $cgi  = shift;
   
    my $path = $cgi->path_info();
    my $handler = $dispatch{$path};


    if (ref($handler) eq "CODE") {
        print "HTTP/1.0 200 OK\r\n";
        $handler->($cgi);

    } else {
        print "HTTP/1.0 404 Not found\r\n";
        print $cgi->header,
              $cgi->start_html('Not found'),
              $cgi->h1('Not found'),
              $cgi->end_html;
    }
}
 
sub resp_hello {
    my $cgi  = shift;   # CGI.pm object
    return if !ref $cgi;
     
    my $who = $cgi->param('name');
     
    print $cgi->header,
          $cgi->start_html("Hello $who title"),
          $cgi->h1("Hello $who!"),
	  $cgi->end_html;
	}
}
sub start_server{

my $ADDR = shift;
my $server = Server->new();

$server->setup(port => 80,8080);
$server->host($ADDR);
$server->background();

}

1;
