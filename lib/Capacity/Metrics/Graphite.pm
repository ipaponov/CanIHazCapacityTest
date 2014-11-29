package Capacity::Metrics::Graphite;

use Moo;
with 'Capacity::Metrics::Prepare';

sub send {
    my $self = shift;
    my $data = shift;

    # Send your metrics to graphite
}

1;
