package Capacity::Metrics::UDP;

use Moo;
with 'Capacity::Metrics::Prepare';

use IO::Socket::INET;

has send_to_addr => (
    is      => 'ro',
    default => 'localhost'
);

has send_to_port => (
    is      => 'ro',
    default => '5000'
);

sub send {
    my $self = shift;
    my $data = shift;

    $data = $self->metrics_to_json($data);

    my $socket = IO::Socket::INET->new(
        Proto    => 'udp',
        PeerPort => $self->send_to_port,
        PeerAddr => $self->send_to_addr
    ) or die "Could not create socket: $!";

    $socket->send($data) or die "Send error: $!";
}

1;
