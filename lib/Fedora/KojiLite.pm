#############################################################################
#
# A minimal interface to Fedora's buildsystem (koji).
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/11/2009 12:06:09 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::KojiLite;

use Moose;

use Data::UUID;
use Digest::MD5 qw{ md5_hex };
use MIME::Base64;
use Path::Class;
use IO::Socket::SSL;
use Sub::Override;
use Sub::Install qw{ install_sub };
use Readonly;

Readonly my $KOJI => 'koji.fedoraproject.org';

use namespace::clean -except => 'meta';

with 'MooseX::Role::XMLRPC::Client' => {
    name       => '_koji',
    uri        => "http://$KOJI/kojihub",
    login_info => 0,
    #cookiejar => "$ENV{HOME}/.koji.cookies",
};

our $VERSION = '0.01';

$RPC::XML::ALLOW_NIL = 1;

# debugging
use Smart::Comments '###', '####';

has session_id => (
    is => 'rw', 
    isa => 'Str',
    predicate => 'has_session_id',
    clearer   => '_clear_session_id',
);

has session_key => (
    is => 'rw', 
    isa => 'Str',
    predicate => 'has_session_key',
    clearer   => '_clear_session_key',
);

has is_logged_in => (is => 'rw', isa => 'Bool', lazy_build => 1);
sub _build_is_logged_in { }

sub LWP::Protocol::https::_extra_sock_optsXXX {
    my ($self, $host, $port) = @_;

    warn "$host";

    if ($host eq 'koji.fedoraproject.org') {
        warn "setting SSL bits...";
        warn "$ENV{HOME}/.fedora.cert";
        return (
            SSL_use_cert    => 1,
            SSL_verify_mode => 0x01,
            SSL_ca_file     => "$ENV{HOME}/.fedora-server-ca.cert",
            SSL_cert_file   => "$ENV{HOME}/.fedora.cert",
            SSL_key_file    => "$ENV{HOME}/.fedora.cert",
        );
    }

    return;
}

sub ssl_login {
    my $self = shift @_;

    unless ($self->has_session_id && $self->has_session_key) {
    
        my @params = (
            SSL_use_cert    => 1,
            SSL_verify_mode => 0x01,
            SSL_ca_file     => "$ENV{HOME}/.fedora-server-ca.cert",
            SSL_cert_file   => "$ENV{HOME}/.fedora.cert",
            SSL_key_file    => "$ENV{HOME}/.fedora.cert",
        );
    
        my $override;
        if (LWP::Protocol::https->can('_extra_sock_opts')) {

            # just override it
            $override = Sub::Override->new(
                'LWP::Protocol::https::_extra_sock_opts' => sub { @params }
            );
        }
        else {
        
            install_sub({ 
                code => sub { return @params if $_[1] eq "$KOJI" },
                into => 'LWP::Protocol::https', 
                as   => '_extra_sock_opts',
            });
        }

        $self->_koji_uri("https://$KOJI/kojihub");
        $self->_clear_koji_rpc;
        my $ret = $self->_koji_rpc->simple_request('sslLogin');

        ### $ret
        $self->session_id($ret->{'session-id'});
        $self->session_key($ret->{'session-key'});
    }

    my $uri = URI->new("http://$KOJI/kojihub"); 
    $uri->query_form(
        'session-id'  => $self->session_id, 
        'session-key' => $self->session_key,
    );
    $self->_koji_uri($uri);
    $self->_clear_koji_rpc;

    ### new uri: $self->_koji_uri
    return;
}

sub upload_file {
    my ($self, $file) = @_;

    ### file: "$file"

    my $contents = $file->slurp;
    my $md5 = md5_hex($contents);

    my $loc = 'cli-build/' . Data::UUID->new->create_str;
    my $fn  = $file->basename;

    $self->_auth_rpc->simple_request('uploadFile',
        $loc,
        #$file->basename,
        $fn,
        $file->stat->size,
        #md5_hex($contents),
        $md5,
        0,
        encode_base64($contents)
    );

    $self->_auth_rpc->simple_request('uploadFile',
        $loc,
        #$file->basename,
        $fn,
        $file->stat->size,
        #md5_hex($contents),
        $md5,
        -1,
        encode_base64(q{})
    );
    
    ### loc: $loc
    #return "$loc/" . $file->basename;
    return "$loc/$fn";
}

# also, buildFromCVS(url, tag)
# where url like 
# cvs://cvs.fedoraproject.org/cvs/pkgs?rpms/perl-Perl-Critic/devel#perl-Perl-Critic-1_092-2_fc11

sub build {
    my ($self, $src, $target, $opts) = shift @_;

    $opts   ||= {};
    $target ||= 'dist-rawhide';

    if (blessed $src && $src->isa('Path::Class::File')) {

        # first, upload it...
        $src = $self->upload_file($src);
        $opts->{scratch} = 'True';
    }

    my $tid = $self->_auth_rpc->simple_request('build', $src, $target, $opts);

    return $tid;
}

__PACKAGE__->meta->make_immutable;

#__END__

package main;

#use DateTime::Easy;
use DateTime;
use Path::Class;

my $koji = Fedora::KojiLite->new(
    #session_id  => 1780563, 
    #session_key => '143-721mcMD1Gyf4EjsVvxD',
);

my $file = file 'perl-local-lib-1.004003-1.fc12.src.rpm';

#my $ret = $koji->_auth_rpc->simple_request('sslLogin');
$koji->ssl_login;

#$koji->upload_file($file);

#my $hm = $koji->_auth_rpc->simple_request('build', 
#    "cli-build/foobarbaz/$file", 'dist-f10', { scratch => 'True' }
#);

#my $hm = $koji->_auth_rpc->simple_request('taskFinished', 1428024);
my $hm = $koji->_koji_rpc->simple_request('taskFinished', 1428503);

### $hm

my $foo = $koji->_koji_rpc->simple_request('getTaskInfo', 1331210);
### $foo
$foo = $koji->_koji_rpc->simple_request('getTaskInfo', 1331209);
### $foo
$foo = $koji->_koji_rpc->simple_request('getTaskResult', 1331210);
### $foo
$foo = $koji->_koji_rpc->simple_request('getTaskResult', 1331209);
### $foo

$foo = $koji->_koji_rpc->simple_request('getTaskChildren', 1331210); 
### $foo 
$foo = $koji->_koji_rpc->simple_request('getTaskChildren', 1331209);
### $foo

$foo = $koji->_koji_rpc->simple_request('listPackages', 'dist-f11');
### $foo

my $dt = DateTime->now->subtract(days => 1);
$foo = $koji->_koji_rpc->simple_request('getLastEvent', $dt->epoch);
### $foo

my $id = $foo->{id};
#$foo = $koji->_koji_rpc->simple_request('getLatestBuilds', 'dist-f12', $id, RPC::XML::nil->new);
#$foo = $koji->_koji_rpc->simple_request('getLatestBuilds', 'dist-f12', undef, 'perl-Moose');
#$foo = $koji->_koji_rpc->simple_request('getLatestBuilds', 'dist-f12', $id, undef);
#$foo = $koji->_koji_rpc->simple_request('getLatestBuilds', 85, $id, undef);
#$foo = $koji->_koji_rpc->simple_request('getLatestBuilds', 'dist-f12', { event => $id });
#$foo = $koji->_koji_rpc->simple_request('listBuilds', 'dist-f12', );
#$foo = $koji->_koji_rpc->simple_request('getTag', 'dist-f12');
#$foo = $koji->_koji_rpc->simple_request('getCapabilities');
#$foo = $koji->_koji_rpc->simple_request('system.listMethods');
$foo = $koji->_koji_rpc->simple_request('system.methodSignature', 'getLatestBuilds');
### $foo


$foo = $koji->_koji_rpc->simple_request('_listapi');
### $foo


__END__

=head1 NAME

Fedora::KojiLite - simplistic Koji access until we have a real Fedora::Koji

=head1 SYNOPSIS

    use Fedora::KojiLite;

    # ... update, build, etc

=head1 DESCRIPTION

This is an overly simplistic interface to Fedora's buildsystem, Koji.  It's
poorly documented, and expected to be folded into a "real" L<Fedora::Koji>
before too long.

Please note that while this is in the Fedora::* namespace, given the proper
buildsystem URI it should work with any other Koji implementation.  I don't
know of any, however :)

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



