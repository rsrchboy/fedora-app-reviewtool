#############################################################################
#
# Plugins... 
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

package Fedora::App::ReviewTool::Plugins;

our $VERSION = '0.001';

use Module::Pluggable::Ordered 
    search_path => [ 'Fedora::App::ReviewTool::Plugin' ];

# th-th-that's all, folks! :)

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Plugins - Handle our plugins

=head1 SYNOPSIS

    use Fedora::App::ReviewTool::Plugins;

    # ...
    Fedora::App::ReviewTool::Plugins->call_plugins('event', ...);


=head1 DESCRIPTION

This package provides an interface to working with our plugins.

Plugins, that should at least have their calling events documented here.
Soon, I promise :)

=head1 EVENTS

=head2 take_for_review

=head2 review

=head1 SEE ALSO

L<Module::Pluggable::Ordered>

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


