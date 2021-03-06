package Capacity;

use Moo;

use Data::Dumper;
use File::Slurp;
use Log::Any qw($log);
use Time::HiRes qw(sleep);

use Capacity::Metrics;
use Capacity::Test;

has configuration_file => (
    is      => 'ro',
    default => '/home/ipaponov/OSS/CanIHazCapacityTest/conf/test.conf'
);

has stop_file => (
    is      => 'ro',
    default => '/home/ipaponov/OSS/CanIHazCapacityTest/conf/stop'
);

has test         => ( is => 'rw' );
has metrics      => ( is => 'rw' );

sub BUILD {
    my $self = shift;

    $self->test(Capacity::Test->new());
    $self->metrics(Capacity::Metrics->new());
}

# main run sub
# should work for about 60 seconds, more or less
# and do whatever test you'll ask it to do
# if there is no test configuration file in place -> exit
# if there is empty configuration file -> exit
# if there is a stop file in place -> exit
sub run {
    my $self = shift;

    my $start_time = time();

    # in case initialization took some time
    #
    # NOTE that if you'll run this software from command line
    # and you're in the middle of the minute
    # start time variable will still point you to the beginning of that minute
    # and that's expected
    # since this software is designed to run as a cronjob
    my $offset = $start_time % 60;
    $start_time -= $offset;
    $log->trace('Start epoch: '.$start_time);

    # read config file
    eval {
        $self->read_config();
        1;
    } or do {
        $log->info('Read config file failed: '.($@ || "Zombie error"));
        exit;
    };

    my $current_time = time();
    my $test_counter = 0;

    while ($current_time <= $start_time + 59) {

        # check for stopfiles
        if (-e $self->stop_file) {
            $log->info('Stop file found: '.$self->stop_file);
            exit;
        }

        # okay, so we're ready to run capacity test here
        # ideally we would like to randomize test execution times a bit,
        # however even without any randomness we'll probably have only first test in sync
        # and since each test takes random time to finish, all other tests won't overlap much
        # BUT
        # let's say we want to have 2 tests per minute, without any extra logic,
        # tests will be done in the first couple of seconds and that's it.
        # But we'd like to distribute them over the whole minute
        #
        # In order to address that requirement
        # we will dinamically calculate approx. time that we have for 1 test
        # approx. time = (time left / nr. of tests left)
        # and sleep for rand(approx. time)

        my $time_left = 60 - (time() - $start_time);
        $log->trace("This script will live for ${time_left} more seconds");

        my $tests_left = $self->test->freq() - $test_counter;
        $log->trace("We need to run ${tests_left} more tests");

        my $approx_time_per_test = $time_left / $tests_left;
        my $sleep_for = rand($approx_time_per_test);
        $log->trace('We are going to sleep for: '.$sleep_for);
        sleep($sleep_for);

        $self->test->run($self->metrics);
        $test_counter++;

        if ($test_counter == $self->test->freq()) {
            $log->info('I\'m done with all those test. See ya!');
            exit;
        }

        # update current_time, otherwise we'll be in an endless loop
        $current_time = time();
    }

    $log->info('We\'re out of time. See ya!');
}

sub read_config {
    my $self = shift;

    # read config file
    $log->trace('About to read config file: '.$self->configuration_file);
    my @lines = ();

    if (-e $self->configuration_file) {
        @lines = read_file($self->configuration_file);
        if (scalar @lines == 0) {
            die 'File is empty';
        }
    } else {
        die 'File does not exists';
    }

    # see NOTE 4 @ README.md
    # only 1 capacity test at a time
    my $test_config = $lines[0];
    chomp $test_config;
    my @test_config = split(/\|/, $test_config);
    $log->trace('Our configuration: '.Dumper(\@test_config));

    $self->test->name($test_config[0]);
    $self->test->type($test_config[1]);
    $self->test->freq($test_config[2]);
    $self->metrics->metrics_destination($test_config[3]);

    $log->trace('Config file was successfully read @ '.time);
}

1;
