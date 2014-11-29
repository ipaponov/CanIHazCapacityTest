#!/usr/bin/perl

use strict;
use IO::Socket;

my $server = IO::Socket::INET->new(LocalPort => 5000, Proto => "udp")
    or die "Can't create UDP server: $@";
my ($datagram,$flags);

while ($server->recv($datagram, 200, $flags)) {
    my $ipaddr = $server->peerhost;
    print "UDP from ${ipaddr}: ${datagram}\n";
}
