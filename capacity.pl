#!/usr/bin/perl

# This is a minimalistic capacity testing toolkit
# It's main purpose is to generate traffic from multiple servers, that's quickly and easily accessible
# via any configuration management tool or func shell for instance

# How to use it?
#  - distribute this software over as many server as you want
#  - put it in the crontabs on those servers, run it every minute
#  - to start capacity test, create test configuration files on set of servers (via func shell, puppet, chef)
#  - remove test configuration files, to stop capacity testing


# Configuration file
#  path to file: Capacity->configuration_file
#  format: test_name|test_type|test_frequency|metrics_destination
#
# test_name
#   human readable name, used in the metric that your test will generate
# test_type
#   based on this type, we will define which class to use in our test
#   see Capacity->capacity_tests_list for list of available options
# test_frequency
#   how often do you want to run your test, within a minute
#   1 - once a minute
#   60 - once a second
# metrics_destination
#   where we want to send our test results
#   see Capacity::Metrics->metrics_destinations_list for list of available options


# NOTE 1
# This script is intended to run as a cron job
# therefore no ARGV parsing here
# all configurations are done via files

# NOTE 2
# since it will be a cron job
# the highest possible execution frequency will be - minutely
# we will keep this script alive for 60 seconds,
# in order to be able to provide constant load of requests

# NOTE 3
# Imagine a situation where the sevice we're testing is really slow,
# and request timeouts are high, because of that we might end up in situation where we have
# multiple instances of this script running on the same server
# let's not spawn more then 3 copies

# NOTE 4
# this tool is not designed to run multiple capacity tests in parallel
# especially becasuse test configurations are distibuted via fsh
# it's very easy to overwrite someone's else configurations
# but I'm willing to pay that price for the sake of simplicity

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
