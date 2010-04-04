package Fedora::App::ReviewTool::Command::review;

=head1 NAME

Fedora::App::ReviewTool::Command::review - [reviewer] review a package

=cut

use Moose;
use namespace::autoclean;

use IO::Prompt;

# debugging
#use Smart::Comments;

extends 'MooseX::App::Cmd::Command';
with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Koji';
with 'Fedora::App::ReviewTool::Reviewer';

sub run {
    my ($self, $opts, $args) = @_;
    
    print "Retrieving reviews status from bugzilla....\n\n";
    my $bugs = $self->find_my_active_reviews;
    print $bugs->num_ids . " bugs found.\n\n";
    print $self->bug_table($bugs) if $bugs->num_ids;

    # right now we assume we've been passed either bug ids or aliases; ideally
    # we should even search for a given review ticket from a package name

    return unless $self->yes || prompt 'Begin reviews? ', -YyNn1;

    PKG_LOOP:
    for my $bug ($bugs->bugs) {
    
        my $name = $bug->package_name;
        print "\nFound bug $bug; $name.\n";
        $self->do_review($bug) 
            if $self->yes || prompt 'Begin review? ', -YyNn1;
        
    }
}

1;

__END__
