package DPKG::Log::Analyse;


=head1 NMAE

DPKG::Log::Analyse - Analyse a dpkg log

=head1 SYNOPSIS

use DPKG::Log;

my $analyser = DPKG::Log::Analyse->new('filename' => 'dpkg.log');
$analyser->analyse;

=head1 DESCRIPTION

This module is used to analyse a dpkg log.

=head1 METHODS

=over 4

=cut

our $VERSION = "0.01";

use 5.010;
use strict;
use warnings;

use Carp;
use DPKG::Log;
use Params::Validate qw(:all);

=item $dpkg_log = DPKG::Log->new('filename' => 'dpkg.log')

Returns a new DPKG::Log::Analyse object.
Filename parameter can be ommitted, it defaults to /var/log/dpkg.log.

=cut
sub new {
    my $package = shift;

    my %params = validate(@_,
        {
            'filename' => { 'type' => SCALAR, 'default' => '/var/log/dpkg.log' },
        }
    );
    
    my $self = {
        packages => {},
        newly_installed_packages => {},
        removed_packages => {},
        upgraded_packages => {}
    };

    if ($params{'filename'}) {
        $self->{'filename'} = $params{'filename'};
    }
    $self->{dpkg_log} = DPKG::Log->new('filename' => $self->{'filename'});
    $self->{dpkg_log}->parse;

    bless($self, $package);

    
    return $self;
}

sub analyse {
    my $self = shift;
    my $dpkg_log = $self->{dpkg_log};

    foreach my $entry ($dpkg_log->entries) {
        next if not $entry->package;
        
        # Initialize data structure if this is a package
        my $package = $entry->package;
        if (not defined $self->{packages}->{$package}) {
            $self->{packages}->{$package} = {};
        }

        if ($entry->type eq 'action') {
            if ($entry->action eq 'install') {
                $self->{newly_installed_packages}->{$package} = 1;
                $self->{packages}->{$package}->{new_version} = $entry->available_version;
            } elsif ($entry->action eq 'upgrade') {
                $self->{upgraded_packages}->{$package} = 1;
                $self->{packages}->{$package}->{previous_version} = $entry->installed_version;
                $self->{packages}->{$package}->{new_version} = $entry->available_version;
            } elsif ($entry->action eq 'remove') {
                $self->{removed_packages}->{$package} = 1;
                $self->{packages}->{$package}->{previous_version} = $entry->installed_version;
            }
        } elsif ($entry->type eq 'status') {
            $self->{packages}->{$package}->{status} = $entry->status;
        }
    }

    use Data::Dumper;
    print "All packages:\n";
    print Dumper($self->{packages});
    print "Newly installed:\n";
    print Dumper($self->{newly_installed_packages});
    print "Removed:\n";
    print Dumper($self->{removed_packages});
    print "Upgraded:\n";
    print Dumper($self->{upgraded_packages});
}

=back

=head1 AUTHOR

This module was written by Patrick Schoenfeld <patrick.schoenfeld@credativ.de>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Patrick Schoenfeld <patrick.schoenfeld@credativ.de>

This library is free software.
You can redistribute it and/or modify it under the same terms as perl itself.

=cut

1;
# vim: expandtab:ts=4:sw=4
