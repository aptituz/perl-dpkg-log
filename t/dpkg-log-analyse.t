use Test::More tests => 18;
use lib 'lib';
use DPKG::Log::Analyse;
use Data::Dumper;

my $analyser;
ok( $analyser = DPKG::Log::Analyse->new('filename' => 'test_data/dpkg.log'), 'init DPKG::Log::Analyse');
isa_ok($analyser, "DPKG::Log::Analyse", '$analyser');
ok( $analyser->analyse, "running analyse returns a true value");
can_ok("DPKG::Log::Analyse", "newly_installed_packages");
can_ok("DPKG::Log::Analyse", "upgraded_packages");
can_ok("DPKG::Log::Analyse", "removed_packages");
can_ok("DPKG::Log::Analyse", "unpacked_packages");
can_ok("DPKG::Log::Analyse", "halfinstalled_packages");
can_ok("DPKG::Log::Analyse", "halfconfigured_packages");
can_ok("DPKG::Log::Analyse", "installed_and_removed_packages");
is( scalar(keys %{$analyser->newly_installed_packages}), 40, "newly_installed_packages returns correct value");
is( scalar(keys %{$analyser->upgraded_packages}), 4, "upgraded_packages returns correct value");
is( scalar(keys %{$analyser->removed_packages}), 1, "removed_packages returns correct value");
is( scalar(keys %{$analyser->unpacked_packages}), 0, "unpacked_packages returns correct value");
is( scalar(keys %{$analyser->halfinstalled_packages}), 0, "halfinstalled_packages returns correct value");
is( scalar(keys %{$analyser->halfconfigured_packages}), 0, "halfconfigured_packages returns correct value");
is( scalar(keys %{$analyser->installed_and_removed_packages}), 1, "installed_and_removed_packages returns correct value");
ok($analyser = $analyser->new('filename' => 'test_data/dpkg.log'), "init DPKG::Log::Analyse from existing ref");
