package DPKG::Log::Analyse::Package;


=head1 NMAE

DPKG::Log::Analyse::Package - Describe a package as analysed from a dpkg.log

=head1 SYNOPSIS

use DPKG::Log;

my $package = DPKG::Log::Analyse::Package->new('package' => 'foobar');

=head1 DESCRIPTION

This module is used to analyse a dpkg log.

=head1 METHODS

=over 4

=cut

our $VERSION = "1.00";

use 5.010;
use strict;
use warnings;

use Carp;
use DPKG::Log;
use Dpkg::Version;
use Params::Validate qw(:all);

use overload (
    '""' => 'as_string',
    'eq' => 'equals',
    'cmp' => 'compare',
    '<=>' => 'compare'
);
=item $package = DPKG::Log::Analyse::Package->new('package' => 'foobar')

Returns a new DPKG::Log::Analyse::Package object.

=cut
sub new {
    my $package = shift;

    my %params = validate(@_,
        {
            'package' => { 'type' => SCALAR },
            'version' => 0,
            'previous_version' => 0,
            'status' => 0
        }
    );
    
    my $self = {
        version => "",
        previous_version => "",
        status => "",
        %params
    };

    bless($self, $package);
    return $self;
}
=item $package->name

Returns the name of thispackage.

=cut
sub name {
    my $self = shift;
    return $self->{package};
}

=item $package->version

Return or set the version of this package.

=cut
sub version {
    my ($self, $version) = @_;
    if ($version) {
        my $version_obj = Dpkg::Version->new($version);
        $self->{version} = $version_obj;
    } else {
        return $self->{version};
    }
}

=back

=head1 Overloading

This module explicitly overloads some operators.
Each operand is expected to be a DPKG::Log::Analyse::Package object.

The string comparison operators, "eq" or "ne" will use the string value for the
comparison.

The numerical operators will use the package name and package version for
comparison. That means a package1 == package2 if package1->name equals
package2->name AND package1->version == package2->version.

The module stores versions as Dpkg::Version objects, therefore sorting
different versions of the same package will work.

This module also overloads stringification returning either the package
name if no version is set or "package_name/version" if a version is set. 
=cut
sub equals {
    my ($first, $second) = @_;
    return ($first->as_string eq $second->as_string);
}


sub compare {
    my ($first, $second) = @_;
    return -1 if ($first->name ne $second->name);
    return ($first->version <=> $second->version);

}

sub as_string {
    my $self = shift;

    my $string = $self->{package};
    if ($self->version) {
        $string = $string . "/" . $self->version;
    }
    return $string;
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