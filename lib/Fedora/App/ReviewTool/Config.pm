package Fedora::App::ReviewTool::Config;

use Moose::Role;
use namespace::autoclean;
use MooseX::Types::Path::Class ':all';
use MooseX::Types::URI qw{ Uri };

use autodie 'system';

use Config::Tiny;
use File::Slurp 'slurp';
use Path::Class;

# debug
#use Smart::Comments '###', '####';

our $VERSION = '0.10_01';

#############################################################################
# Attributes

has test => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    documentation => q{Test only -- don't run against "real" bugs/components},
);

has yes => (
    traits        => [ 'Getopt' ],
    is            => 'ro',
    isa           => 'Bool',
    cmd_aliases   => 'y',
    default       => 0,
    documentation => q{Assume yes; don't prompt},
);


#############################################################################
# Configuration bits

with 'MooseX::ConfigFromFile';

requires '_sections';

has configfile => (
    is            => 'rw',
    isa           => File,
    coerce        => 1,
    default       => "$ENV{HOME}/.reviewtool.ini",
    documentation => 'configuration file to use',
);

has _config => (
    is => 'ro',
    isa => 'Config::Tiny',
    lazy_build => 1,
);

sub _build__config { Config::Tiny->read(shift->configfile) }

sub get_config_from_file {
    my ($class, $file) = @_;

    my $config = Config::Tiny->read($file);

    ### hmm: $config

    my %c;
    CFG_LOOP:
    for my $key ($class->_sections) {
    
        # skip if we don't have that section
        next CFG_LOOP unless exists $config->{$key};

        ### $key
        %c = (%c, %{ $config->{$key} });
    };

    return \%c;
}

#############################################################################
# Logging

use Log::Log4perl qw{ :easy };
with 'MooseX::Log::Log4perl';

has debug => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    documentation => 'Enable somewhat verbose logging',
);

before run => sub { shift->enable_logging };

sub enable_logging {
    my $self = shift @_;

    if ($self->debug) {
        Log::Log4perl->easy_init($DEBUG);
        return;
    }
    
    # otherwise we just want the informative bits
    Log::Log4perl->easy_init($INFO);

    return;
}

#############################################################################
# Editor (temp files, etc) bits 

has editor => (
    is => 'ro', isa => 'Str', default => '/usr/bin/vim',
    documentation => 'The external editor to use (default: vim)',
);

sub external_edit {
    # my ($self, $file, $text) = @_;
    my $self   = shift @_;
    my $file   = (shift @_ || file(File::Temp->new(UNLINK => 0)->filename));
    my $text   = shift @_;
    my $editor = $self->editor;

    # write file neatly handles scalar and array refs, as well
    write_file($file, $text) if $text;

    # run the editor, return the file...  note we'll ABEND if aborted
    system "$editor $file";
    return $file;
}

1;

__END__
