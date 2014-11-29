package Capacity::Metrics;

use Moo;

use Data::Dumper;
use Hash::Merge qw(merge);
use Log::Any qw($log);

has metrics_destinations_list => (
    is      => 'rw',
    default => sub { return {
        udp       => 'Capacity::Metrics::UDP',
        cassandra => 'Capacity::Metrics::Cassandra',
        graphite  => 'Capacity::Metrics::Graphite'
    }}
);

has default_metrics_destination => (
    is      => 'ro',
    default => 'udp'
);

has metrics_destination => (
    is      => 'rw'
);

has metrics => (
    is => 'rw',
    default => sub {{}}
);

has sending_metrics_is_important => (
    is => 'ro',
    default => 1,
    documentation => q|
        If something wrong happens when you try to send your metrics, what should be we do?
        If metrics are really not that important (when you have enough monitoring on your cluster
        that you're testing or/and you don't want to annoy people with tons of emails) set
        this value to 0.
        Otherwise set it to 1, and code will die if something will go wrong.
    |
);

sub add_data {
    my $self = shift;
    my $data = shift;

    if (ref $data && ref $data eq 'HASH') {
        my $metrics = $self->metrics();
        $self->metrics(merge($metrics, $data));
    } else {
        die "we want hash ref!";
    }
}

sub send {
    my $self = shift;

    # let's find out where we want to send our metrics
    # if we have some bullshit in metrics_destination
    # we'll use default value

    my $md = $self->metrics_destination;
    if ($md && !exists $self->metrics_destinations_list()->{$md}) {
        $self->metrics_destination(undef);
    }

    if (!defined $self->metrics_destination) {
        $self->metrics_destination($self->default_metrics_destination);
    }
    $log->trace('Metrics destination will be: '.$self->metrics_destination);
    $log->trace('Metrics hash looks like this: '.Dumper($self->metrics));

    my $destination_class = $self->metrics_destinations_list()->{$self->metrics_destination};

    eval "require $destination_class"
    or do {
        $log->error("Require failed. $@");
        # do not die here
        # this sub might be called within eval
        exit;
    };

    eval {
        my $d = $destination_class->new();
        $d->send($self->metrics);
        1;
    } or do {
        if ($self->sending_metrics_is_important) {
            $log->error('We failed to send out metrics: '.$@);
            # do not die here
            # this sub might be called within eval
            exit;
        }
        $log->info(
            'We failed to send our metrics: '.($@ || "Zombie error")
        );
    };

    # clean up
    $self->metrics({});
}

1;
