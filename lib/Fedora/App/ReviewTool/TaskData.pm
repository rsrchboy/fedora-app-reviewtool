#############################################################################
#
# Keep track of information as we execute a task 
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 06/16/2009
#
# Copyright (c) 2009  <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::TaskData;

use Moose;
use MooseX::AttributeHelpers 0.19;
use MooseX::Types::Path::Class ':all';

with 'MooseX::Log::Log4perl';

use namespace::clean -except => 'meta';

our $VERSION = '0.001';

has bug => 
    (is => 'ro', isa => 'Fedora::Bugzilla::PackageReviewBug', required => 1);

has review_dir => (is => 'ro', isa => Dir, coerce => 1, required => 1);
has cmd => (is => 'ro', isa => 'MooseX::App::Cmd::Command', required => 1);

#has flag => ...

has data => (
    traits => [ 'Collection::Hash' ],

    is   => 'rw',
    isa  => 'HashRef',
    lazy => 1,

    provides => {
    
        exists   => 'has_datum',
        empty    => 'has_data',
        defined  => 'data_is_defined',
        accessor => 'datum',
        get      => 'get_datum',
        set      => 'set_datum',
        keys     => 'data_keys',
    },
);
sub _build_data { { } }

# the review/comment text
has text => (
    traits => [ 'Collection::Array' ],

    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub { [ ] },

    provides => {
        empty   => 'has_text',
        push    => 'add_text',
        unshift => 'prepend_text',
        clear   => 'clear_text',
    },
);

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Fedora::App::ReviewTool::TaskData - Keep track of our data

=head1 SYNOPSIS

    use Fedora::App::ReviewTool::Plugins;

    # ...
    Fedora::App::ReviewTool::Plugins->call_plugins('event', ...);


=head1 DESCRIPTION

This package allows us to keep track of what's going on, as we go from one
plugin to another.

=head1 SEE ALSO

L<Fedora::App::ReviewTool>

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009  <cweyl@alumni.drew.edu>

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


