package Config::Loader;

our $VERSION = '0.01';
use Moo;


=head1 NAME

Config::Loader

=head1 SYNOPSIS

    use Config::Loader;

Use 'file' to specify the config file. Leave off the extension if you want to let
Config::Any look for a file of any extension.

    my $config = Config::Loader->new( file => 'config/test.pl' );

If you supply a <uc(name)>_CONFIG environment variable with a file name as specified
in the 'file', it will be used instead:

    $ENV{ZYYSSY_CONFIG} = 'config/some-config-file.pl'

    my $config_hash = $config->config;

    my $cloned_config = $config->clone;

You can pass in a 'default' config:

    my $config = Config::Loader->new( file => 'config/my_config.pl', default => { home => '...' } );

Variables can be installed using the 'substitute' attribute. Installed by default
are: HOME, path_to, and literal.

    file => 'xyzzx.pl' or 'xyzzx.conf', etc   # name of file

    dir -  the directory to search in

    home => 'Something'   # this or 'path_to'  will be used when substituting HOME

    some_key => '__literal(__DATA__)__'

    substitute => {
        literal => sub {
            return "Literally, $_[1]!";
        },
        two_plus_two => sub {
            return 2 + 2;
        },
    }

    driver_args  - hashref of args passed through to Config::Any

    local_suffix - default is 'local'. Constructs additional config file names such as xyzzy_local.pl

    no_local  -  don't use local suffix to rerieve a local version of config

    no_env  - Set this to 1 to disregard anything in the ENV. The 'env_lookup' option will be ignored. Off by default

    env_lookup - Additional ENV to check if $ENV{<NAME>...} is not found


To install a 'config' accessor into the package. For example, if
the 'name' is MyApp, it will install a MyApp::config method, which
will return the config hash

    install_accessor_into => 'MyApp'

Environment variables to check :
Uppercase versions of these as "prefix"

   name  'myapp' (actual file part of the 'file' param)
   env_lookup  ['xyz', 'abc']
   package name converted, for example MyApp::Config => myapp_config
   $prefix_$suffix

CONFIG_LOCAL_SUFFIX environment variable overrides 'local_suffix'

=cut


use Carp;
use Config::Any;
use Hash::Merge::Simple;
use Sub::Install;
use Data::Visitor::Callback;
use List::MoreUtils ('any');
use Clone();
use File::Spec;

has 'name' => ( is => 'rw' );
has 'dir' => ( is => 'rw', lazy => 1, builder => '_build_path' );
sub _build_dir { return '.'; }
has 'file' => ( is => 'ro', required => 1 );
has path_to => ( is => 'ro', reader => '_path_to', lazy => 1, builder => '_build_path_to' );
sub _build_path_to {
    my $self = shift;
    return $self->config->{home} if $self->config->{home};
    return $self->dir if $self->dir;
    return '.';
}
has substitute => ( is => 'rw', lazy => 1, builder => '_build_substitute' );
sub _build_substitute { {} }
has default => ( is => 'ro', lazy => 1, builder => '_build_default' );
sub _build_default { {} }
has _config => ( is => 'rw' );
has 'install_accessor_into' => ( is => 'ro' );
has 'driver_args' => ( is => 'ro' );

#flags
has load_once => ( is => 'ro', default => 1 );
has 'loaded'  => ( is => 'ro', default => 0 );
has 'no_local' => ( is => 'ro', default => 0 );
has 'no_env' => ( is => 'ro' );
has 'files_found' => ( is => 'rw' );
has 'env_lookup' => ( is => 'ro', default => sub { [] } );
has local_suffix => ( is => 'ro', lazy => 1, builder => 'build_local_suffix' );
sub build_local_suffix { 'local' }

=head2 BUILD

=cut

sub BUILD {
    my $self = shift;

    my $file = $self->file;
    my ( $vol, $dirs, $filename ) = File::Spec->splitpath($file);
    $self->name($filename);
    $self->dir($dirs);

    if ( my $package = $self->install_accessor_into ) {
        Sub::Install::install_sub(
            {
                code => sub {
                    return $self->config;
                },
                into => $package,
                as   => "config"
            }
        );

    }

    if ( defined $self->env_lookup ) {
        $self->{env_lookup} = [ $self->env_lookup ] unless ref $self->env_lookup eq "ARRAY";
    }
}

=head2 config

=cut

sub config {
    my $self = shift;
    return $self->_config if $self->loaded;
    return $self->load;
}

sub get { shift->config }

=head2 load

=cut

sub load {
    my $self = shift;

    if ( $self->loaded && $self->load_once ) {
        return $self->get;
    }
    # start with default config, if any
    $self->_config( $self->default );

    # get config hashes from all config files
    my @files   = $self->get_files;
    my @configs = $self->get_config_from_files(@files);
    $self->_merge_and_save_config($_) for @configs;
    $self->{loaded} = 1;
    {
        my $visitor = Data::Visitor::Callback->new(
            plain_value => sub {
                return unless defined $_;
                $self->do_substitutions($_);
            }
        );
        $visitor->visit( $self->config );

    }

    return $self->config;
}

=head reload

=cut

sub reload {
    my $self = shift;
    $self->{loaded} = 0;
    return $self->load;
}

=head2 _merge_and_save_config

=cut

sub _merge_and_save_config {
    my ( $self, $cfg ) = @_;

    # lose the filename, merge the config hashes
    my ( $filename, $hash ) = %$cfg;
    my $config = Hash::Merge::Simple->merge( $self->_config, $hash );
    $self->_config($config);
}

=head2 get_config_from_files

=cut

sub get_config_from_files {
    my ( $self, $files ) = @_;

    my $cfg_files = Config::Any->load_files(
        {
            files       => $files,
            use_ext     => 1,
            driver_args => $self->driver_args,
        }
    );
    my %cfg_files = map { (%$_)[0] => $_ } reverse @$cfg_files;
    $self->files_found( [ map { (%$_)[0] } @$cfg_files ] );

    my ( @cfg, @local_cfg );
    {
        # Anything that is local takes precedence
        my $local_suffix = $self->_get_local_suffix;
        for ( sort keys %cfg_files ) {

            my $cfg = $cfg_files{$_};

            if (m{$local_suffix\.}ms) {
                push @local_cfg, $cfg;
            }
            else {
                push @cfg, $cfg;
            }
        }
    }

    return $self->no_local ? @cfg : ( @cfg, @local_cfg );
}

=head2 get_files

=cut

sub get_files {
    my $self = shift;

    my $path = $self->_env_lookup('CONFIG') unless $self->no_env;
    $path ||= $self->file;

    my ($extension) = $path =~ m{\.([^/\.]{1,4})$};

    my $local_suffix = $self->_get_local_suffix;
    my @extensions   = @{ Config::Any->extensions };
    my $no_local     = $self->no_local;
    my @files;
    if ($extension) {
        croak "Can't handle file extension $extension"
            unless any { $_ eq $extension } @extensions;
        push @files, $path;
        unless ($no_local) {
            ( my $local_path = $path ) =~ s{\.$extension$}{_$local_suffix.$extension};
            push @files, $local_path;
        }
    }
    else {
        push @files, map { "$path.$_" } @extensions;
        push @files, map { "${path}_${local_suffix}.$_" } @extensions unless $no_local;
    }

    return \@files;
}

=head2 _env_lookup

In _get_files: $path = $self->_env_lookup('CONFIG') unless $self->no_env;

=cut

sub _env_lookup {
    my ( $self, @suffix ) = @_;

    my $name       = $self->name;
    my $env_lookup = $self->env_lookup;
    my @lookup;
    push @lookup, $name if $name;
    push @lookup, @$env_lookup;

    for my $prefix (@lookup) {
        my $key = uc join "_", ( $prefix, @suffix );
        $key =~ s/::/_/g;
        $key =~ s/\W/_/g;
        my $value = $ENV{$key};
        return $value if defined $value;
    }

    return;
}

=head2 _get_local_suffix

=cut

sub _get_local_suffix {
    my $self = shift;
    my $suffix = $ENV{'CONFIG_LOCAL_SUFFIX'} unless $self->no_env;
    $suffix ||= $self->local_suffix;
    return $suffix;
}

=head2 do_substitutions

=cut

sub do_substitutions {
    my $self = shift;

    my $substitution = $self->substitute;
    $substitution->{HOME}    ||= sub { shift->path_to(''); };
    $substitution->{path_to} ||= sub { shift->path_to(@_); };
    $substitution->{literal} ||= sub { return $_[1]; };
    my $matcher = join( '|', keys %$substitution );

    for (@_) {
        s{__($matcher)(?:\((.+?)\))?__}{ $substitution->{ $1 }->( $self, $2 ? split( /,/, $2 ) : () ) }eg;
    }
}

=head2 path_to

This is used for subsitutions in the config file entries

=cut

sub path_to {
    my $self = shift;
    my @path = @_;

    my $path_to = $self->_path_to;

    my $path = Path::Class::Dir->new( $path_to, @path );
    if ( -d $path ) {
        return $path;
    }
    else {
        return Path::Class::File->new( $path_to, @path );
    }
}

1;
