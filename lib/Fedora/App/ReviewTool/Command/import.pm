#############################################################################
#
# Provides a 'import' command to Fedora::App::ReviewTool.
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/07/2009 11:02:10 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Command::import;

use autodie 'system';

use Moose;

use MooseX::Types::Path::Class ':all';

use File::Slurp;
use IO::Prompt;
use IPC::System::Simple;
use Path::Class;
use URI::Fetch;

# debugging...
#use Smart::Comments;

use namespace::clean -except => 'meta';

extends qw{ MooseX::App::Cmd::Command }; 

with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Bodhi';
with 'Fedora::App::ReviewTool::Submitter';

our $VERSION = '0.09';

sub _sections { qw{ bugzilla fas } }

has tmpdir => (is => 'ro', isa => Dir, coerce => 1, lazy_build => 1);
sub _build_tmpdir { File::Temp::tempdir }

has cvs_root => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_cvs_root 
    { ':ext:' . shift->app->cn . '@cvs.fedora.redhat.com:/cvs/extras' }

sub run {
    my ($self, $opts, $args) = @_;
   
    $self->enable_logging;
    $self->app->startup_checks;

    my $bugs;
    
    if (@$args == 0) {

        print "Finding our submitted bugs...\n";
        $bugs = $self->find_my_submissions;
    }
    else {

        # go after the ones on the command line...
        # FIXME should probably do some sanity checking here...
        $bugs = $self->_bz->bugs($args);
    }

    print "Found bugs $bugs.\n\n";

    my $dir  = $self->tmpdir;
    my $root = $self->cvs_root;

    BUG_LOOP:
    for my $bug ($bugs->bugs) {

        my $pkg = $bug->package_name;

        print "Checking $bug ($pkg)...\n";
        do { print "$pkg ($bug) not ready to be imported.\n\n"; next BUG_LOOP }
            unless $bug->ready_for_import;

        print "$bug has been approved, branched, and is ready for CVS import.\n";
        next BUG_LOOP unless ($self->yes || prompt "Import $bug? ", -YyNn1);

        chdir "$dir";
        $self->_run(
            "cvs -d $root co $pkg && cd $pkg && make common",
            "\nChecking out $pkg module from cvs ($dir)",
        );

        print "\nSearching for latest SRPM...\n";
        my @uris = $bug->grep_uris(sub { /\.src\.rpm$/ });
        my $srpm_uri;
        if    (@uris == 1) { $srpm_uri = $uris[0]                      }
        elsif (@uris  > 1) { $srpm_uri = $self->_pick_srpm_uri(@uris)  }
        else               { die "no srpm uris in $bug?!\n"           } 

        print "Using $srpm_uri.\nFetching...\n";
        my $r = URI::Fetch->fetch($srpm_uri) || die URI::Fetch->errstr;
        my @parts = $srpm_uri->path_segments;
        my $srpm = file($dir, $parts[-1]);
        write_file "$srpm", $r->content;

        print "\nImporting and building in devel...\n\n";
        my $cvs_cmd = "echo | ./cvs-import.sh -m 'Initial import.'";
        my $bodhi_cmd = "bodhi -n -t newpackage -R stable -c 'New package.'";

        chdir "$dir/$pkg/common";
        #system "$cvs_cmd -b devel $srpm";
        $self->_run("$cvs_cmd -b devel $srpm");
        chdir "$dir/$pkg/devel";
        #system "cvs update && make build";
        $self->_run("cvs update && make build");

        # FIXME
        for my $branch ('F-9', 'F-10', 'F-11') {

            print "\nImporting and building in $branch...\n\n";
            chdir "$dir/$pkg/common";
            system "$cvs_cmd -b $branch $srpm";
            chdir "$dir/$pkg/$branch";
            #system "cvs update && make build";
            system "cvs update";
            system "make build";
            #system "$bodhi_cmd `make verrel`";
            ##system "bodhi -n -t newpackage -R stable -c 'New package.'";
            my $build = `make verrel`;
            chomp $build;

            # let's see if this works...
            $self->submit_bodhi_newpackage($build);

            #$self->submit_bodhi(
            #    'save',
            #    builds => $build,
            #    request => 'stable',
            #    notes => 'New package for this release',
            #    suggest_reboot => 0,
            #    close_bugs => 0,
            #    unstable_karma => -3,
            #    stable_karma => 3,
            #    inheritance => 0,
            #    bugs => q{},
            #    type_ => 'newpackage',
            #);

            print "\n\n$branch import done.\n\n";
        }

        if ($self->yes || prompt "Close $bug? ", -YyNn1) {

            $bug->close_nextrelease(comment => 'Thanks for the review! :-)');
            print "$bug closed.\n\n";
        }
        else { print "$bug NOT closed.\n\n" }
    }

    return;
}

sub _usage_format {
    return 'usage: %c close %o';
}

sub _run {
    my ($self, $cmd, $msg) = @_;

    print "$msg...\n" if $msg;

    # force a subshell so redirect works correctly for compound statements
    my $out = `($cmd) 2>&1`;

    return unless $?;

    # something Bad happened if we're here
    die "Command failed: $?\n";
}

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Command::import - [submitter] import packages

=head1 DESCRIPTION

Import packages that have been reviewed and branched.

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



