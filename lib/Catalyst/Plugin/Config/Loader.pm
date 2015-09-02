package Catalyst::Plugin::Config::Loader;

use strict;
use warnings;

use Class::Load ('load_class');

sub setup {
    my $class = shift;

    # create the package name of the app's Config file
    my $config_package = $class . '::Config';
    load_class($config_package);
    # get existing config.
    my $cfgl_config = $class->config->{'Plugin::Config::Loader'};
    # create the config loader object
    my $loader = $config_package->new( %$cfgl_config );
    # get the config hash
    my $config = $loader->config;
    # save the config. This method in Catalyst::Component will merge the existing config and the new config
    $class->config($config);
    # hook for applications
    $class->finalize_config;
    $class->next::method( @_ );
}

# this is just here as a hook for applications classes to override
sub finalize_config {
    my $class = shift;
}

1;
