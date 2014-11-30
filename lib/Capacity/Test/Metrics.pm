package Capacity::Test::Metrics;

use Moo::Role;
use Log::Any qw($log);
use Time::HiRes qw(gettimeofday);

has timer => (
    is      => 'rw',
    default => 0
);

has metrics => (
    is      => 'rw',
    default => sub {{}}
);

before 'test' => sub {
    my $self = shift;
    $log->trace('About to run test: '.ref($self));
    my ($seconds, $microseconds) = gettimeofday;
    $log->trace('Now is: '.$seconds.'.'.$microseconds);
    $self->timer($seconds.'.'.$microseconds);
};

after 'test' => sub {
    my $self = shift;
    my ($seconds, $microseconds) = gettimeofday;
    $log->trace('I\'m done. Now is: '.$seconds.'.'.$microseconds);
    $self->timer(($seconds.'.'.$microseconds) - $self->timer());
    $log->trace(
        sprintf('Test completed in %.2f s', $self->timer())
    );

    my $metrics = { 'test_time' => $self->timer };
    $metrics->{'test_epoch'} = time;
    $self->metrics($metrics);
};

1;
