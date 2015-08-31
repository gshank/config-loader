use strict;
use warnings;

use Test::Most;

use Path::Class;
use Config::Loader;
my $config;

$config = Config::Loader->new(
    file => 't/var/default',
    default => {
        home => 'a-galaxy-far-far-away',
        test => 'alpha',
    },
);

is($config->get->{home}, 'a-galaxy-far-far-away', 'got home');
is($config->get->{path_to}, dir('a-galaxy-far-far-away', 'tatooine'), 'got path_to');
is($config->get->{test}, 'beta', 'got test');

done_testing;
