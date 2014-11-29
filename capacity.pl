#!/usr/bin/perl

use IPC::ConcurrencyLimit;
use Log::Any::Adapter ('Stdout');

use Capacity;

my $guard = IPC::ConcurrencyLimit->new(
    max_procs => 3,
    path      => '/var/lock/capacity_testing'
);

my $id = $guard->get_lock();
if ($id) {
    my $capacity_test = Capacity->new();
    $capacity_test->run();
}
