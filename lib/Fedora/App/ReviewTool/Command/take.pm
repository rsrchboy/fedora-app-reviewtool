#############################################################################
#
# Take a posted package review request for review
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/01/2009 11:50:00 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Command::take;

=head1 NAME

Fedora::App::ReviewTool::Command::take - [reviewer] take a package for review

=cut

use Moose;
use namespace::autoclean;

use IO::Prompt;
use Path::Class;

# debugging
#use Smart::Comments;

extends 'MooseX::App::Cmd::Command';
with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Bodhi';
with 'Fedora::App::ReviewTool::Koji';
with 'Fedora::App::ReviewTool::Reviewer';

#with 'MooseX::Role::XMLRPC::Client' => {
#    name       => '_koji',
#    #uri        => 'http://koji.fedoraproject.org/kojihub',
#    login_info => 0,
#};
#sub _build__koji_uri { warn 'here'; return 'https://koji.fedoraproject.org/kojihub' }

sub run {
    my ($self, $opts, $args) = @_;
    
    $self->log->info('Starting take process.');

    # right now we assume we've been passed either bug ids or aliases; ideally
    # we should even search for a given review ticket from a package name

    PKG_LOOP:
    for my $id (@$args) {

        $self->log->info("Working on RHBZ#$id");
        
        # FIXME check!
        my $bug  = $self->_bz->bug($id);
        my $name = $bug->package_name;

        # FIXME basic "make sure bug is actually a review tix"

        print "\nFound: bug $bug, package $name\n\n";
        print $self->bug_table($bug) . "\n";

        # FIXME we should prompt to mark/check for FE-SPONSORNEEDED
        print "Checking to ensure packager is sponsored...\n\n";        
        print "*** WARNING *** Submitter is not in 'packager' group!\n\n"
            unless $self->has_packager($bug->reporter);

        if ($bug->has_flag('fedora-review')) {

            #if ($bug->get_flag('fedora-review') eq
            print "Bug has fedora-review set; not taking.\n\n";
        }
        elsif ($self->yes || prompt "Take review request? ", -YyNn1) {

            print "\nTaking...\n";

            $bug->assigned_to($self->userid);
            $bug->update;
            $bug->set_flags('fedora-review' => '?');

            print "$bug assigned and marked under review.\n";
        }

        $self->do_review($bug) 
            if $self->yes || prompt 'Begin review? ', -YyNn1;
        
        print "\n";
    }

    return;
}

__END__

=head1 DESCRIPTION

This package provides a "take" command for reviewtool.

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



