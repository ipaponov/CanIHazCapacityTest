package Capacity;

use Moo;

use Data::Dumper;
use File::Slurp;
use Log::Any qw($log);

use Capacity::Metrics;

has capacity_tests_list => (
    is      => 'rw',
    default => sub { return {
        'riak_read'      => 'Capacity::Test::RiakRead',
        'cassandra_read' => 'Capacity::Test::CassandraRead',
        'google_test'    => 'Capacity::Test::GoogleTest'
    }}
);

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

has test_name    => ( is => 'rw' );
has test_type    => ( is => 'rw' );
has test_freq    => ( is => 'rw' );
has metrics      => ( is => 'rw' );

sub BUILD {
    my $self = shift;

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
            next;
        };


        # TODO
        # Run tests according to specified frequency in the configuration file

        $self->test();
        sleep(2);
    }
}

sub test {
    my $self = shift;

    # I do not want to do it in attribute isa, because I do not want to die
    # and generate storm of errors from multiple servers
    # instead I want to send metrics-document
    my $tt = $self->test_type;
    if ($tt && !exists $self->capacity_tests_list()->{$tt}) {
        $log->info('Unknown capacity test type, sending inforamtion about that');
        $self->metrics->add_data( {'error' => { 'unknown capacity test type' => $tt }} );
        $self->metrics->send();

        return;
    }

    my $test_class = $self->capacity_tests_list()->{$tt};

    eval "require $test_class"
    or do {
        $log->error("Require failed. $@");
        # do not die here
        # log everything silently and exit
        exit;
    };

    my $t = $test_class->new(metrics_destination => $self->metrics);
    eval {
        $t->test();

        $self->metrics->add_data($t->metrics);
        $self->metrics->add_data({ test_name => $self->test_name });
        $self->metrics->send();
        1;
    } or do {
        # probably network issues, good luck next time
        $log->info('Something failed during the test: '.$@);
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

    # see NOTE 4 @ capacity.pl
    # only 1 capacity test at a time
    my $test_config = $lines[0];
    chomp $test_config;
    my @test_config = split(/\|/, $test_config);
    $log->trace('Our configuration: '.Dumper(\@test_config));

    $self->test_name($test_config[0]);
    $self->test_type($test_config[1]);
    $self->test_freq($test_config[2]);
    $self->metrics->metrics_destination($test_config[3]);

    $log->trace('Config file was successfully read @ '.$self->config_read_at);
}

1;
