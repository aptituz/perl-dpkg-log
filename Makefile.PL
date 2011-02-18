use inc::Module::Install;
  
# Define metadata
name           'DPKG-Log';
abstract       'Parse and analyse dpkg log files';
author         'Patrick Schoenfeld <schoenfeld@debian.org>';
all_from       'lib/DPKG/Log.pm';
no_index directory => 'tools';
no_index directory => 'examples';

# Specific dependencies
requires       'DateTime';
requires       'DateTime::Format::Strptime';
requires       'DateTime::TimeZone';
requires       'Params::Validate';
test_requires  'Test::More';

WriteAll;
