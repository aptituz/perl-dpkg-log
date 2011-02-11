=head1 NMAE

DPKG::Log - Parse the dpkg log

=head1 SYNOPSIS

use DPKG::Log;

my $dpkg_log = DPKG::Log->new('filename' => 'dpkg.log', 'parse' => 1);

=head1 DESCRIPTION

This module is used to parse a logfile and store each line
as a DPKG::Log::Entry object.

=head1 METHODS

=over 4

=cut

package DPKG::Log;
our $VERSION = "0.01";

use 5.010;
use strict;
use warnings;

use Carp;
use DPKG::Log::Entry;
use DateTime::Format::Strptime;
use DateTime::TimeZone;
use Params::Validate qw(:all);
use Data::Dumper;

# 2011-02-03 07:54:46
our $timestamp_re = '([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})';

# 2011-02-03 07:54:59 startup packages configure
our $startup_line_re = "$timestamp_re startup ([^ ]+) ([^ ]+)";

# 2011-02-03 07:54:59 status unpacked libproc-processtable-perl 0.45-1
our $status_line_re = "$timestamp_re status ([^ ]+) ([^ ]+) ([^ ]+)";

# 2011-02-03 07:54:59 configure libproc-daemon-perl 0.06-1 0.06-1
our $action_line_re = "$timestamp_re ([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+)";

=item $dpkg_log = DPKG::Log->new()

=item $dpkg_log = DPKG::Log->new('filename' => 'dpkg.log')

=item $dpkg_log = DPKG::Log->new('filename' => 'dpkg.log', 'parse' => 1 )


Returns a new DPKG::Log object. If parse is set to a true value the logfile
specified by filename is parsed at the end of the object initialisation.
Otherwise the parse routine has to be called.
Filename parameter can be ommitted, it defaults to /var/log/dpkg.log.

=cut
sub new {
    my $package = shift;

    my %params = validate(@_,
        {
            'filename' => { 'type' => SCALAR, 'default' => '/var/log/dpkg.log' },
            'parse' => 0
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

    if ($params{'parse'}) {
        $self->parse;
    }

    return $self;
}

=item $dpkg_log->filename

=item $dpkg_log->filename('newfilename.log')

Get or set the filename of the dpkg logfile.

=cut
sub filename {
    my $self = shift;
    @_ ? $self->{'filename'}=shift : $self->{filename};
}

=item $dpkg_log->parse

Call the parser.

=cut
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

=item @entries = $dpkg_log->entries;

Return all entries.

=cut
sub entries {
    my $self = shift;
    return @{$self->{entries}};
}

=item $entry = $dpkg_log->next_entry;

Return the next entry. Beware that this function shifts the next entry and therefore
changes the object.

=cut
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
