#!/usr/bin/perl -I.

use strict;
use warnings;
use NetAddr::IP;
use TWebServer;

my $mod=$ARGV[0] or die system("lolcat -F 0.5 logo;\ echo Use perl licenta.pl h for more details.");
my $delete;
if(defined $ARGV[1]){
	$delete=$ARGV[1];
}

sub checkroot{
	if($> != 0){
		die "Must be root";
	}
}
	my $count=11;
        my $NS="Fake";
        my $INTERFACE="wlp3s0";
        my $VETH0="xveth0";
        my $VPEER="xveth1";
        my $VETHX="xveth";
        my $VETH0_ADDR=new NetAddr::IP '192.168.1.20/24';
        my $VPEER_ADDR=new NetAddr::IP '192.168.1.21/24';
        my $VETHX_ADDR=new NetAddr::IP '192.168.1.22/24';
	my @pid;

if($mod eq 'h'){
	die system("lolcat -F 0.5 logo;\ echo Use:;
	echo perl lic.perl a to create all things
	echo perl lic.perl d to delete all the things; echo");
}
elsif($mod eq 'a'){

	checkroot();
	system("lolcat -F 0.5 logo;\ echo");
	print "Creating namespace\n";
	system("ip netns add $NS");
	if(! -e "/etc/netns/$NS/resolv.conf"){
		system("mkdir -p /etc/netns/$NS");
		system("touch /etc/netns/$NS/resolv.conf");
		system("echo 'nameserver 8.8.8.8' > /etc/netns/$NS/resolv.conf");
	}
	
	print "Creating Virtual eths and moving them to $NS namespace\n";
	system("ip link add $VETH0 type veth peer name $VPEER");
	system("ip link set $VPEER netns $NS");
	for(my $i=2;$i<$count;$i++){
		system("ip link add $VETHX".$i." type veth");
		system("ip link set $VETHX".$i." netns $NS");
	}
	
	print"Assigning IPs\n";
	system("ifconfig $VETH0 $VETH0_ADDR");
	system("ip netns exec $NS ip link set lo up");
	system("ip netns exec $NS ifconfig $VPEER $VPEER_ADDR");
	system("ip netns exec $NS ip link set $VPEER up");
	my $copie=$VETHX_ADDR->copy();
	for(my $i=2;$i<$count;$i++){
		system("ip netns exec $NS ifconfig $VETHX".$i." $copie");
		system("ip netns exec $NS ip link set $VETHX".$i." up");
		$copie++;
	}
        system("ip netns exec $NS ip route add default via ".$VETH0_ADDR->addr);


	print "Enable IP-Frowarding\n";
	system("echo 1 > /proc/sys/net/ipv4/ip_forward");

	print "Flush forward and nat rules\n";
	system("iptables -P FORWARD DROP");
	system("iptables -F FORWARD");
	system("iptables -t nat -F");

	print "Enable MASQUERADING ON $VETH0\n";
	system("iptables -t nat -A POSTROUTING -s $VETH0_ADDR -o $INTERFACE -j MASQUERADE");
	system("iptables -A FORWARD -i $INTERFACE -o ".$VETH0_ADDR->addr." -j ACCEPT");
	system("iptables -A FORWARD -o $INTERFACE -i ".$VETH0_ADDR->addr." -j ACCEPT");

	$pid[0]=TWebServer::start_server($VETH0_ADDR->addr);
	print "PID code: $pid[0]\n";

}

elsif($mod eq 'd'){

	checkroot();
	system("lolcat -F 0.5 logo;\ echo");
	print "Deleting IPs\n";
	system("ip netns exec $NS ip link del $VPEER");
	my $copie=$VETHX_ADDR->copy();
        for(my $i=2;$i<$count;$i++){
                system("ip netns exec $NS ip link del $VETHX".$i);
                $copie++;
        }
	print "Deleting $NS namespace\n";
	system("ip netns del $NS &>/dev/null");
	print "Final step\n";
	system("iptables -P FORWARD DROP");
	system("iptables -F FORWARD");
	system("iptables -t nat -F");
	if(defined $delete){
		kill $delete;
	}
	print "Yuhuuu goodbye!\n";
}
else{
	die "IDK something is fcked up\n";
}
