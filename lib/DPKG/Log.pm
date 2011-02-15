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

use strict;
use warnings;
use 5.010;

our $VERSION = "0.01";

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

Optionally its possible to specify B<from> or B<to> arguments as timestamps
in the standard dpkg.log format.
This will limit the entries which will be stored in the object to entries in the
given timerange.
Note that, if this is not what you want, you may ommit these attributes and
can use B<filter_by_time()> instead.

By default the module will assume that those timestamps are in the local timezone
as determined by DateTime::TimeZone. This can be overriden by giving the
argument B<time_zone> which takes a timezone string (e.g. 'Europe/Berlin').
Additionally its possible to override the timestamp_pattern by specifying
B<timestamp_format>. This has to be a valid pattern for DateTime::Format::Strptime.

=cut
sub new {
    my $package = shift;

    my %params = validate(@_,
        {
            'filename' => { 'type' => SCALAR, 'default' => '/var/log/dpkg.log' },
            'parse' => 0,
            'time_zone' => { 'type' => SCALAR, 'default' => 'local' },
            'timestamp_pattern' => { 'type' => SCALAR, 'default' => '%F %T' },
            'from' => 0,
            'to' => 0
        }
    );
    my $self = {
        entries => [],
        invalid_lines => [],
        time_zone => undef,
        from => undef,
        to => undef,
        %params
    
    };

    bless($self, $package);
    return $self;
}

=item $dpkg_log->filename

=item $dpkg_log->filename('newfilename.log')

Get or set the filename of the dpkg logfile.

=cut
sub filename {
    my ($self, $filename) = @_;
    if ($filename) {
        $self->{filename} = $filename;
    } else {
        $filename = $self->{filename};
    }
    return $filename;
}

=item $dpkg_log->parse

=item $dpkg_log->parse('time_zone' => 'Europe/Berlin')

Call the parser.

The B<time_zone> parameter is optional and specifies in which time zone
the dpkg log timestamps are.  If its ommitted it will use the default
local time zone.

=cut
sub parse {
    my $self = shift;
    open(my $log_fh, "<", $self->{filename})
        or croak("unable to open logfile for reading: $!");
 
    my %params = validate(@_, { 
            'time_zone' => {  default => $self->{time_zone} },
            'timestamp_pattern' => { default => $self->{timestamp_pattern} },
        } );

    # Determine system timezone
    my $tz =  DateTime::TimeZone->new( 'name' => $params{time_zone} );
    my $ts_parser = DateTime::Format::Strptime->new( 
                        pattern => $params{timestamp_pattern},
                        time_zone => $params{time_zone}
                    );

    my $lineno = 0;
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
            $entry->associated_package($3);
            $entry->installed_version($4);
         } elsif ($line =~ /^$action_line_re/o) {
            $entry->subject('package');
            $entry->type('action');
            $entry->action($2);
            $entry->associated_package($3);
            $entry->installed_version($4);
            $entry->available_version($5);
        } else {
            push(@{$self->{invalid_lines}}, $line);
            next;
        }

        push(@{$self->{entries}}, $entry);
    }
    close($log_fh);

    if ($self->{from} or $self->{to}) {
        @{$self->{entries}} = ($self->filter_by_time(
             from => $self->{from},
             to => $self->{to},
             entry_ref => $self->{entries}));
    }

    return scalar(@{$self->{entries}});
}

=item @entries = $dpkg_log->entries;

=item @entries = $dpkg_log->entries('from' => '2010-01-01 00:00:00', to => '2010-01-02 24:00:00')

Return all entries or all entries in a given timerange.

B<from> and B<to> are optional arguments, specifying a date before (from) and after (to) which
entries aren't returned.
If only B<to> is specified all entries from the beginning of the log are read.
If only B<from> is specified all entries till the end of the log are read.

=cut
sub entries {
    my $self = shift;
    my %params = validate(@_, 
                {  
                    from => 0,
                    to => 0,
                    time_zone => { type => SCALAR, default => $self->{time_zone} }
                }
    );
    croak "Object does not store entries. Eventually parse function were not run or log is empty. " if (not @{$self->{entries}});

    if (not ($params{from} or $params{to})) {
        return @{$self->{entries}};
    } else {
        return $self->filter_by_time(from => $params{from},
            to => $params{to},
            time_zone => $params{time_zone});
    }
}

=item $entry = $dpkg_log->next_entry;

Return the next entry. Beware that this function shifts the next entry and therefore
changes the object.

=cut
sub next_entry {
    my $self = shift;
    return shift(@{$self->{entries}});
}

=item @entries = $dpkg_log->filter_by_time(from => ts, to => ts)

=item @entries = $dpkg_log->filter_by_time(from => ts)

=item @entries = $dpkg_log->filter_by_time(to => ts)

=item @entries = $dpkg_log->filter_by_time(from => ts, to => ts, entry_ref => $entry_ref)

Filter entries by given B<from> - B<to> range. See the explanations for
the new sub for the arguments.

If entry_ref is given and an array reference its used instead of $self->{entries}
as input source for the entries which are to be filtered.
=cut
sub filter_by_time {
    my $self = shift;
    my %params = validate( @_,
        {
            from => 0,
            to => 0,
            time_zone => { default => $self->{time_zone} },
            timestamp_pattern => { default => $self->{timestamp_pattern} },
            entry_ref => { default => $self->{entries} },
        }
    );
    
    my @entries = @{$params{entry_ref}};
    if (not @entries) {
        croak "Object does not store entries. Eventually parse function were not run or log is empty.";
    }

    # Initialize timestamp parser
    my $ts_parser = DateTime::Format::Strptime->new( 
                        pattern => $params{timestamp_pattern},
                        time_zone => $params{time_zone}
                    );

    my $from_dt;
    my $to_dt;
    if ($params{from}) {
        $from_dt = $ts_parser->parse_datetime($params{from});
    } else {
        $from_dt = $entries[0]->timestamp;
    }
    if ($params{to}) {
        $to_dt = $ts_parser->parse_datetime($params{to});
    } else {
        $to_dt = $entries[-1]->timestamp;
    }

    @entries = grep { ($_->timestamp >= $from_dt) and ($_->timestamp <= $to_dt) } @entries;
    return @entries;
}

=item ($from, $to) = $dpkg_log->get_datetime_info()

Returns the from and to timestamps of the logfile or (if from/to values are set) the
values set during object initialisation.

=cut
sub get_datetime_info() {
    my $self = shift;

    my $from;
    my $to;
    if ($self->{from}) {
        $from = $self->{from};
    } else {
        $from = $self->{entries}->[0]->timestamp;
    }

    if ($self->{to}) {
        $to = $self->{to};
    } else {
        $to = $self->{entries}->[-1]->timestamp;
    }
    return ($from, $to);
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
