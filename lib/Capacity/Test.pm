package Capacity::Test;

use Moo;
use Log::Any qw($log);

has name    => ( is => 'rw' );
has type    => ( is => 'rw' );
has freq    => ( is => 'rw' );

has capacity_tests_list => (
    is      => 'rw',
    default => sub { return {
        'riak_read'      => 'Capacity::Test::RiakRead',
        'cassandra_read' => 'Capacity::Test::CassandraRead',
        'google_test'    => 'Capacity::Test::GoogleTest'
    }}
);

sub run {
    my $self = shift;
    my $metrics = shift;

    # I do not want to do it in attribute isa,
    # because I do not want to die
    # and generate storm of errors from multiple servers
    # instead I want to send metrics-document
    my $tt = $self->type;
    if ($tt && !exists $self->capacity_tests_list()->{$tt}) {
        $log->info('Unknown capacity test type, sending inforamtion about that');
        $metrics->add_data( {'error' => { 'unknown capacity test type' => $tt }} );
        $metrics->send();

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

    my $t = $test_class->new();
    eval {
        $t->test();

        $metrics->add_data($t->metrics);
        $metrics->add_data({ test_name => $self->name });
        $metrics->send();
        1;
    } or do {
        # probably network issues, good luck next time
        $log->info('Something failed during the test: '.$@);
    }
}

1;
