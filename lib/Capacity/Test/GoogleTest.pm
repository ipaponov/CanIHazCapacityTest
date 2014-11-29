package Capacity::Test::GoogleTest;

use Moo;
use LWP::UserAgent;
use HTTP::Request;

with 'Capacity::Test::Metrics';

sub test {
    my $self = shift;

    my $ua = LWP::UserAgent->new;
    $ua->agent("DummyCapTest/0.1 ");

    my $req = HTTP::Request->new(GET => 'http://google.com');
    my $res = $ua->request($req);
}

1;
