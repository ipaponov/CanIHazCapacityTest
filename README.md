CanIHazCapacityTest
===================

This is a minimalistic capacity testing toolkit.

It's main purpose is to generate traffic from multiple servers,
that's quickly and easily accessible via any configuration management
tool or func shell for instance.

How to use it?
-----------
 * distribute this software over as many server as you want
 * put it in the crontabs on those servers, run it every minute
 * to start capacity test, create test configuration files on set of servers (via func shell, puppet, chef)
 * remove test configuration files, to stop capacity testing (or create a stop file, to temp. test freeze).

Software will react relatively fast when you'll create new configuration file. At most you'll have to wait for 1 minute.  
Same goes for configuration changes, if file exists.  
As for the stop file - it will stop capacity testing immediately.  

Configuration file
-----------
path to file: *Capacity->configuration_file*  
format: test_name|test_type|test_frequency|metrics_destination

**test_name**  
Human readable name, used in the metric that your test will generate.

**test_type**  
Based on this type, we will define which class to use in our test.  
See *Capacity::Test->capacity_tests_list* for the list of available options.

**test_frequency**  
How often do you want to run your test within a minute?  
1 - once a minute  
60 - once a second  
We will try to run that number of tests within a minute, but we do not guarantee that all of those will be executed.
Software will stop our software after 60(ish) seconds of work. And if your test requires 10 seconds to pass, and you want 60 of those per minute. Well, no. You'll get only 6-7 of those.  

**metrics_destination**  
Where we want to send our test results?  
See *Capacity::Metrics->metrics_destinations_list* for the list of available options.


NOTE 1
-----------
This script is intended to run as a cron job,
therefore no ARGV parsing here.  
All configurations are done via files.

NOTE 2
-----------
Since it will be a cron job,
the highest possible execution frequency will be - minutely.
We will keep this script alive for 60 seconds,
in order to be able to provide constant load of requests.

NOTE 3
-----------
Imagine a situation where the sevice we're testing is really slow,
and request timeouts are high, because of that we might end up in situation where we have
multiple instances of this script running on the same server.
Let's not spawn more then 3 copies.

NOTE 4
-----------
This tool is not designed to run multiple capacity tests in parallel.
Especially becasuse test configurations are distibuted via func shell,
it's very easy to overwrite someone's else configurations.  
But I'm willing to pay that price for the sake of simplicity.
