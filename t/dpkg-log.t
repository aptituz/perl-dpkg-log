use Test::More tests => 8;
use lib 'lib';
use DPKG::Log;

my $dpkg_log;
my $filename;
ok($dpkg_log = DPKG::Log->new(), "initialize DPKG::Log object");
ok($filename = $dpkg_log->filename, "filename() returns filename");
ok($dpkg_log->filename("test.log"), "filename('test.log')");
is($dpkg_log->filename, "test.log", "filename() returns 'test.log'");

$dpkg_log->filename('test_data/dpkg.log');
ok($dpkg_log->parse > 0, "parse() returns a value greater 0" );
is(scalar(@{$dpkg_log->{invalid_lines}}), 0, "0 invalid lines" );
ok($entry = $dpkg_log->next_entry, "next entry returns an entry" );
isa_ok($entry, "DPKG::Log::Entry", "entry");
