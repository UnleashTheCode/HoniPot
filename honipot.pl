#!/usr/bin/perl -I./Modules


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
use NetAddr::IP;
use Getopt::Long;
use Storable;


sub checkroot{
	if($> != 0){
		die "Must be root";
	}
}
	my $help;
	undef my $mod;
	my $count=11;
        my $NS="Fake";
        my $INTERFACE="wlp3s0";
        my $VETH0="xveth0";
        my $VPEER="xveth1";
        my $VETHX="xveth";
        my $VETH0_ADDR=new NetAddr::IP '192.168.1.20/24';
        my $VPEER_ADDR=new NetAddr::IP '192.168.1.21/24';
        my $VETHX_ADDR=new NetAddr::IP '192.168.1.22/24';
	my @adresses;
	my @adresses_addr;
	push @adresses_addr,$VPEER_ADDR;
	my @pid;

	if ( -e "adresses"){
        my @adresses=@{retrieve 'adresses'};
        }
        
	if ( -e "pids"){
        my @pid=@{retrieve 'pids'};
        }
        
GetOptions("mod=s" => \$mod,
	"count=i" => \$count, #number of fake interfaces
	"ns|namespace=s" => \$NS, #Namespace name
	"interface=s" => \$INTERFACE,
	"h" => \$help)
	or die system("lolcat -F 0.5 Modules/logo;\ echo Use perl licenta.pl --h for more details.");



if($help or ! defined $mod){
	die system("lolcat -F 0.5 Modules/logo;\ echo Use:;
	echo perl lic.perl --mod a to create all things
	echo perl lic.perl --mod d to delete all the things
	echo Optional:
	echo --count INT number of interfaces
	echo --ns or --namespace STR the namespace name
	echo --interface STR name of interface using;echo");
}
elsif($mod eq 'a'){

	checkroot();
	system("lolcat -F 0.5 Modules/logo;\ echo");
	print "Creating namespace\n";
	system("ip netns add $NS");
	if(! -e "/etc/netns/$NS/resolv.conf"){
		system("mkdir -p /etc/netns/$NS");
		system("touch /etc/netns/$NS/resolv.conf");
		system("echo 'nameserver 1.1.1.1' > /etc/netns/$NS/resolv.conf");
	}
	
	print "Creating Virtual eths and moving them to $NS namespace\n";
	system("ip link add $VETH0 type veth peer name $VPEER");
	system("ip link set $VPEER netns $NS");
	if(!@adresses){
        for(my $i=2;$i<$count;$i++){
            system("ip netns exec $NS ip link add $VETHX".$i." type veth");
            push @adresses , join('',$VETHX,$i);
        }
        store \@adresses,'adresses';
    }
    else{
        foreach (@adresses){
            system("ip link add $_ type veth");
            }
        }
	
	print"Assigning IPs\n";
	system("ip addr add $VETH0_ADDR dev $VETH0");
    system("ip link set $VETH0 up");
	system("ip netns exec $NS ip link set lo up");
	system("ip netns exec $NS ip addr add $VPEER_ADDR dev $VPEER");
	system("ip netns exec $NS ip link set $VPEER up");
    system("ip netns exec $NS ip route add default via ".$VETH0_ADDR->addr);
	my $copie=$VETHX_ADDR->copy();
	foreach (@adresses){
		#if(!defined@adresses_addr){
            system("ip netns exec $NS ip addr add $copie dev $_");
            system("ip netns exec $NS ip link set $_ up");
            push @adresses_addr,$copie;
            $copie++;	
        }

	print "Enable IP-Frowarding\n";
	system("echo 1 > /proc/sys/net/ipv4/ip_forward");

	print "Enable MASQUERADING ON $VETH0\n";
    system("iptables -t nat -A POSTROUTING -s $VETH0_ADDR -o $INTERFACE -j MASQUERADE");
    system("iptables -A FORWARD -i $INTERFACE -o $VETH0 -j ACCEPT");
	system("iptables -A FORWARD -o $INTERFACE -i $VETH0 -j ACCEPT");
    
	foreach (@adresses_addr){
		system("ip netns exec Fake perl Modules/TWebServer.pl ".$_->addr);
		system("ip netns exec Fake perl Modules/TSMTPServer.pl ".$_->addr."&");
	}
	print "\n";
}

elsif($mod eq 'd'){

	checkroot();
	system("lolcat -F 0.5 Modules/logo;\ echo");
	print "Deleting IPs\n";
	system("ip netns exec $NS ip link del $VPEER");
    if(@adresses){
        foreach (@adresses){
            system("ip netns exec $NS ip link del $_");
        }
    }
    else
    {
        for(my $i=2;$i<$count;$i++){
                system("ip netns exec $NS ip link del $VETHX".$i);
            }
    }
    if(@pid){
        foreach (@pid){
            kill $_;
        }
    }
	print "Final step\n";
	print "Deleting $NS namespace\n";
	system("ip netns del $NS &>/dev/null");
	
	print "Yuhuuu goodbye!\n\n";
}
else{
	die "IDK something is fcked up\n";
}
