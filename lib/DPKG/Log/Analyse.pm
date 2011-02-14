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

=item $analyser->analyse;

Analyse the debian package log.

=cut
sub analyse {
    my $self = shift;
    my $dpkg_log = $self->{dpkg_log};

    foreach my $entry ($dpkg_log->entries) {
        next if not $entry->associated_package;
        
        # Initialize data structure if this is a package
        my $package = $entry->associated_package;
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
}

=item $analyser->newly_installed_packages

Return all packages which were newly installed in the dpkg.log.

=cut
sub newly_installed_packages {
    my $self = shift;
    return keys %{$self->{newly_installed_packages}};
}

=item $analyser->upgraded_packages


Return all packages which were upgraded in the dpkg.log.

=cut
sub upgraded_packages {
    my $self = shift;
    return keys %{$self->{upgraded_packages}};
}

=item $analyser->removed_packages


Return all packages which were removed in the dpkg.log.

=cut
sub removed_packages {
    my $self = shift;
    return keys %{$self->{removed_packages}};
}

=item $analyser->unpacked_packages


Return all packages which are left in state 'unpacked'.

=cut
sub unpacked_packages {
    my $self = shift;
    my @result;
    foreach my $package (keys %{$self->{packages}}) {
        if ($self->{packages}->{$package}->{status} = "unpacked") {
            push(@result, $package);
        }
    }
}

=item $analyser->halfinstalled_packages


Return all packages which are left in state 'half-installed'.

=cut
sub halfinstalled_packages {
    my $self = shift;
    my @result;
    foreach my $package (keys %{$self->{packages}}) {
        if ($self->{packages}->{$package}->{status} = "half-installed") {
            push(@result, $package);
        }
    }
}

=item $analyser->halfconfigured_packages


Return all packages which are left in state 'half-configured'.

=cut
sub halfconfigured_packages {
    my $self = shift;
    my @result;
    foreach my $package (keys %{$self->{packages}}) {
        if ($self->{packages}->{$package}->{status} = "half-configured") {
            push(@result, $package);
        }
    }
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
