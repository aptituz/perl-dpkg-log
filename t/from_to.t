use Test::More tests => 8;
use lib 'lib';
use DPKG::Log;

my $dpkg_log;
my $filename;
ok($dpkg_log = DPKG::Log->new('filename'=> 'test_data/from_to.log'), "initialize DPKG::Log object");
$dpkg_log->parse;
ok(@entries = $dpkg_log->entries('from' => '2011-02-02 00:00:00', 'to' => '2011-02-03 00:00:00'));
