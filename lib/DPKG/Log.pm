=head1 NMAE

DPKG::Log - Parse the dpkg log

=head1 SYNOPSIS

.. TODO ..

=head1 DESCRIPTION

.. TODO ..

=head1 METHODS

=over 4

=cut

package DPKG::Log;

use 5.010;
use strict;
use warnings;

use Carp;
use DPKG::Log::Entry;
use DateTime::Format::Strptime;
use DateTime::TimeZone;
use Params::Validate qw(:all);
use Data::Dumper;


our $VERSION = "0.01";

# 2011-02-03 07:54:46
our $timestamp_re = '([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})';

# 2011-02-03 07:54:59 startup packages configure
our $startup_line_re = "$timestamp_re startup ([^ ]+) ([^ ]+)";

# 2011-02-03 07:54:59 status unpacked libproc-processtable-perl 0.45-1
our $status_line_re = "$timestamp_re status ([^ ]+) ([^ ]+) ([^ ]+)";

# 2011-02-03 07:54:59 configure libproc-daemon-perl 0.06-1 0.06-1
our $action_line_re = "$timestamp_re ([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+)";

sub new {
    my $package = shift;

    my %params = validate(@_,
        {
            'filename' => { 'type' => SCALAR, 'default' => '/var/log/dpkg.log' }
        }
    );
    my $self = {
        entries => [],
        invalid_lines => []
    
    };
    if ($params{'filename'}) {
        $self->{'filename'} = $params{'filename'};
    }
    bless($self, $package);
    return $self;
}

sub filename {
    my $self = shift;
    @_ ? $self->{'filename'}=shift : $self->{filename};
}

sub parse {
    my $self = shift;
    open(my $log_fh, "<", $self->{filename})
        or croak("unable to open logfile for reading: $!");
   

    # Determine system timezone
    my $tz = DateTime::TimeZone->new( 'name' => 'local' );
    my $ts_parser = DateTime::Format::Strptime->new( 
                        pattern => '%F %T',
                        time_zone => $tz
                    );

    my $lineno = 0;
    my $invalid_lines = 0;
    while  (my $line = <$log_fh>) {
        $lineno++;
    
        my $parse_status = 0;
        my $timestamp;
    
        if ($line =~ /^$timestamp_re/o) {
            $timestamp = $ts_parser->parse_datetime($1);
        } else {
            push(@{$self->{invalid_lines}}, $line);
            next;
        }

        my $entry = DPKG::Log::Entry->new( line => $line, lineno => $lineno, timestamp => $timestamp );
        
        chomp $line;

        if ($line =~ /^$startup_line_re/o) {
            $entry->type('startup');
            $entry->subject($2);
            $entry->action($3);
        } elsif ($line =~ /^$status_line_re/o) {
            $entry->type('status');
            $entry->subject('package');
            $entry->status($2);
            $entry->package($3);
            $entry->installed_version($4);
         } elsif ($line =~ /^$action_line_re/o) {
            $entry->subject('package');
            $entry->type('action');
            $entry->action($2);
            $entry->package($3);
            $entry->installed_version($4);
            $entry->available_version($5);
       } else {
            push(@{$self->{invalid_lines}}, $line);
            next;
        }

        push(@{$self->{entries}}, $entry);
    }
    return scalar(@{$self->{entries}});
}

sub next_entry {
    my $self = shift;
    return shift(@{$self->{'entries'}});
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
