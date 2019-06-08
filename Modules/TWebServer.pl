#!/usr/bin/perl
#HoniPot
#This app is for impoving your home network security. Honipot is an honeypot scripted in perl.
#Copyright (C) <2019> <Teodor-Andrei Dan>

#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <https://www.gnu.org/licenses/>.
use strict;
use warnings;
use CGI;

{
package Server;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use Data::Dumper;


my %dispatch = (
    '/hello' => \&resp_hello,
    # ...
);
 
sub headers {
    my( $self, $headers ) = @_;
    if( $headers ){
        $self->{__last_headers} = { @$headers };
    }
    return $self->{__last_headers};
}

sub handle_request {

    my $self = shift;
    my $cgi  = shift;
    my $header = $self->headers();
    my $path = $cgi->path_info();
    my $handler = $dispatch{$path};
    
    if(! -e "./Logs"){
        system("mkdir ./Logs");
        }
    if(! -e "./Logs/".$self->lookup_localhost){
        system("touch ./Logs/".$self->lookup_localhost);
        }
    my $filename = "./Logs/".$self->lookup_localhost;
    open(FILE, '>>', $filename ) or die $!;
    my $dump = Data::Dumper->Dump([$header], [qw($header)]);
    print FILE "Potential threat: $ENV{REMOTE_ADDR}\n";
    print FILE "Path accesed: ".$path."\n";
    print FILE $dump;
    close FILE;
    
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
my $pid =$server->background();

return ($pid,$server)
}

use Storable;
use NetAddr::IP;

my @pid;
my $ip = new NetAddr::IP shift;
if ( -e "./pids"){
        my @pid=@{retrieve 'pids'};
        }
my ($pi,$serv) = start_server($ip->addr);
push @pid,$pi;
store \@pid,'./pids';
