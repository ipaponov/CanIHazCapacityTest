package Capacity::Test::Metrics;

use Moo::Role;
use Log::Any qw($log);
use Time::HiRes qw(gettimeofday tv_interval);

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
    my $time = [gettimeofday];
    $log->trace('Now is: '.$time->[0].'.'.$time->[1]);
    $self->timer($time);
};

after 'test' => sub {
    my $self = shift;
    my $time = [gettimeofday];
    $log->trace('I\'m done. Now is: '.$time->[0].'.'.$time->[1]);
    $self->timer(tv_interval($self->timer));
    $log->trace(
        sprintf('Test completed in %.2f s', $self->timer())
    );

    my $metrics = { 'test_time' => $self->timer };
    $metrics->{'test_epoch'} = time;
    $self->metrics($metrics);
};

1;
