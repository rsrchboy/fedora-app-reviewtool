#############################################################################
#
# Generate a pretty table showing the status of our open review bugs.
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/06/2009 11:06:18 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Command::status;

use Moose;
use namespace::autoclean;

# debugging
#use Smart::Comments '###', '####';

extends 'MooseX::App::Cmd::Command';
with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Koji';
with 'Fedora::App::ReviewTool::Submitter';

our $VERSION = '0.10_01';

has just_reviews => (
    is => 'rw', isa => 'Bool', default => 0,
    documentation => 'Only list reviews',
);

has just_submissions=> (
    is => 'rw', isa => 'Bool', default => 0,
    documentation => 'Only list submissions',
);

sub _usage_format {
    return 'usage: %c status %o';
}

sub run {
    my ($self, $opts, $args) = @_;
    
    # first things first.
    $self->app->startup_checks;

    unless ($self->just_reviews) {

        print "Retrieving submissions status from bugzilla....\n\n";
        my $bugs = $self->find_my_submissions;
        print $bugs->num_ids . " bugs found.\n\n";
        print $self->bug_table($bugs) if $bugs->num_ids;
    }

    unless ($self->just_submissions) {

        print "Retrieving reviews status from bugzilla....\n\n";
        my $bugs = $self->find_my_active_reviews;
        print $bugs->num_ids . " bugs found.\n\n";
        print $self->bug_table($bugs) if $bugs->num_ids;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Fedora::App::ReviewTool::Command::status - Check up on your reviews 

=head1 SYNOPSIS

This package provides a "status" command for reviewtool, which lists out the
status of reviews (submitted and taken) that are not in a CLOSED state.

=head1 SEE ALSO

L<reviewtool>, L<Fedora::App::ReviewTool>

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the 

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut



