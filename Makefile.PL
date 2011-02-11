use inc::Module::Install;
  
# Define metadata
name           'DPKG-Log';
all_from       'lib/DPKG/Log.pm';
  
# Specific dependencies
requires       'DateTime';
requires       'DateTime::Format::Strptime';
requires       'DateTime::TimeZone';
requires       'Params::Validate';
test_requires  'Test::More';

WriteAll;
