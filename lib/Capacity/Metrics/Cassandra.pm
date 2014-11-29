package Capacity::Metrics::Cassandra;

use Moo;
with 'Capacity::Metrics::Prepare';

sub send {
    my $self = shift;
    my $data = shift;

    # Send your metrics to Cassandra
}

1;
