package Capacity::Metrics::Prepare;

use Moo::Role;
use JSON;

sub metrics_to_json {
    my $self = shift;
    my $data = shift;

    my $json = encode_json $data;

    return $json;
}

1;
