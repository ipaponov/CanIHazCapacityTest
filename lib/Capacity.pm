package Capacity;

use Moo;

use Data::Dumper;
use File::Slurp;
use Log::Any qw($log);

use Capacity::Metrics;
use Capacity::Test;

has configuration_file => (
    is      => 'ro',
    default => '/home/ipaponov/OSS/CanIHazCapacityTest/conf/test.conf'
);

has config_read_at => (
    is      => 'rw',
    default => 0
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
# if there is no test configuration file in place - it will sleep and wait for file
# if there is empty configuration file - it will sleep and wait for content
# if there is a stop file in place - it will exit immediately
sub run {
    my $self = shift;

    my $start_time = time();
    # in case initialization took some time
    my $offset = $start_time % 60;
    $start_time -= $offset;
    $log->trace('Start epoch: '.$start_time);

    my $current_time = time();
    my $test_counter = 0;

    while ($current_time <= $start_time + 59) {
        # check for stopfiles
        if (-e $self->stop_file) {
            $log->info('Stop file found: '.$self->stop_file);
            exit;
        }

        eval {
            $self->read_config();
            1;
        } or do {
            $log->debug('Read config file failed: '.($@ || "Zombie error"));
            # we probably have config file missing, therefore nothing to do
            # let's sleep at bit, to save some cpu cycles
            sleep(1);
            next;
        };


        # TODO
        # Run tests according to specified frequency in the configuration file

        $self->test->run($self->metrics);
        sleep(2);

        # update current_time, otherwise we'll be in an endless loop
        $current_time = time();
    }
}

sub read_config {
    my $self = shift;

    # don't read too often, once every 2 seconds is more then enough
    if ($self->config_read_at > 0 && (time() - $self->config_read_at < 2)) {
        return;
    }

    # read config file
    $log->trace('About to read config file: '.$self->configuration_file);
    my @lines = ();

    # save read attempt time
    $self->config_read_at(time);

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

    $log->trace('Config file was successfully read @ '.$self->config_read_at);
}

1;
