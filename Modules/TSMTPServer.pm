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

package TSMTPServer;
use strict;
use warnings;
use Net::SMTP::Server;
use Net::SMTP::Server::Client;
use Net::SMTP::Server::Relay;
 
 sub start_server{
    my $ADDR = shift;
    my $server = new Net::SMTP::Server($ADDR, 25) ||
    die("Unable to handle client connection: $!\n");
    
    while(my $conn = $server->accept()) {
    my $client = new Net::SMTP::Server::Client($conn) ||
        die("Unable to handle client connection: $!\n");
    $client->process || next;
    my $relay = new Net::SMTP::Server::Relay($client->{FROM},
                                            $client->{TO},
                                            $client->{MSG});
    }
 }
1;
