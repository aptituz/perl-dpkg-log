=head1 NAME

DPKG::Log::Entry - Describe a log entry in a dpkg.log

=head1 SYNOPSIS

use DPKG::Log::Entry;

$dpkg_log_entry = DPKG::Log::Entry->new( line => $line, $lineno => 1)

$dpkg_log_entry->timestamp($dt);

$dpkg_log_entry->package("foo");


=head1 DESCRIPTION

This module is used to describe one line in a dpkg log
by parameterizing every line into generic parameters like

=over 3

=item * Type of log entry (startup-, status-, action-lines)

=item * Timestamp

=item * Subject of log entry (e.g. package, packages or archives)

=item * Package name (if log entry refers to a package subject)

=back

and so on.

The various parameters are described below together with
the various methods to access or modify them. 

=head1 METHODS


=over 4

=cut
package DPKG::Log::Entry;

use strict;
use warnings;

use Params::Validate qw(:all);

=item $dpkg_log_entry = PACKAGE->new( 'line' => $line, 'lineno' => $lineno )

Returns a new DPKG::Log::Entry object.
The arguments B<line> and B<lineno> are mandatore. They store the complete line
as stored in the log and the line number.

Additionally its possible to specify every attribute the object can store,
as 'key' => 'value' pairs.

=back

=cut
sub new {
    my $package = shift;
    my %params = validate( @_, { 
                    'line' => { 'type' => SCALAR },
                    'lineno' => { 'type' => SCALAR },
                    'timestamp' => '',
                    'package' => '',
                    'action' => '',
                    'status' => '',
                    'subject' => '',
                    'type' => '',
                    'installed_version' => '',
                    'available_version' => '',
                  }
    );
    my $self = {
        'line' => $params{line},
        'lineno' => $params{lineno},
        'timestamp' => $params{timestamp} || "",
        'package' => $params{package} || "",
        'action' => $params{action} || "",
        'status' => $params{status} || "",
        'type' => $params{type} || "",
        'subject' => $params{subject} || "",
        'installed_version' => $params{installed_version} || "",
        'available_version' => $params{available_version} || "",
    };
    bless($self, $package);
    return $self;
}

=head1 ATTRIBUTES

=over 4

=item $dpkg_log_entry->line() / line

Return the full log line. This attribute is set on object initialization.

=cut
sub line {
    my $self = shift;
    return $self->{line};
}

=item $dpkg_log_entry->lineno() / lineno

Return the line number of this entry. This attribute is set on object initialization.

=cut
sub lineno {
    my $self = shift;
    return $self->{lineno};
}

=item $dpkg_log_entry->timestamp() / timestamp

Get or set the timestamp of this object. Should be a DateTime object.

=cut
sub timestamp {
    my $self = shift;
    @_ ? $self->{'timestamp'}=shift : $self->{timestamp};
}

=item $dpkg_log_entry->type() / type

Get or set the type of this entry. Specifies weither this is a startup,
status or action line.

=cut 
sub type {
    my $self = shift;
    @_ ? $self->{'type'}=shift : $self->{type};
}

=item $dpkg_log_entry->package() / package

Get or set the package of this entry. This is for lines that are associated to a certain
package like in action or status lines. Its usually unset for startup and status lines.

=cut 
sub package {
    my $self = shift;
    @_ ? $self->{'package'}=shift : $self->{package};
}

=item $dpkg_log_entry->action() / action

Get or set the action of this entry. This is for lines that have a certain action,
like in startup-lines (unpack, configure) or action lines (install, remove).
It is usally unset for status lines.

=cut 
sub action {
    my $self = shift;
    @_ ? $self->{'action'}=shift : $self->{action};
}

=item $dpkg_log_entry->status() / status

Get or set the status of the package this entry refers to.

=cut 
sub status {
    my $self = shift;
    @_ ? $self->{'status'}=shift : $self->{status};
}

=item $dpkg_log_entry->subject() / subject

Gets or Defines the subject of the entry. For startup lines this is usually 'archives' or 'packages'
for all other lines its 'package'.

=cut 

sub subject {
    my $self = shift;
    @_ ? $self->{'subject'}=shift : $self->{subject};
}

=item $dpkg_log_entry->installed_version() / installed_version

Gets or Defines the installed_version of the package this entry refers to.
It refers to the current installed version of the package depending on the
current status. Is "<none>" (or similar) if action is 'install', old version in
case of an upgrade.
=cut 
sub installed_version {
    my $self = shift;
    @_ ? $self->{'installed_version'}=shift: $self->{installed_version};
}

=item $dpkg_log_entry->available_version() / available_version

Gets or Defines the available_version of the package this entry refers to.
It refers to the currently available version of the package depending on the
current status. Is different from installed_version if the action is install or upgrade.
=cut 
sub available_version {
    my $self = shift;
    @_ ? $self->{'available_version'}=shift: $self->{available_version};
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
