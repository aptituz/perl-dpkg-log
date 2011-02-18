use strict;
use warnings;
use lib 'lib';
use Data::Dumper;
use DPKG::Log;

my $dpkg_log = DPKG::Log->new(filename =>'test_data/dpkg.log');
$dpkg_log->parse;
print Dumper($dpkg_log->next_entry);
print Dumper($dpkg_log->next_entry);
