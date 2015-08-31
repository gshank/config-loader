use strict;
use warnings;

use Test::Most;

use Path::Class;
use Config::Loader;
my $config;

$config = Config::Loader->new( file => 't/var/path_to' );

is($config->get->{path_to}, dir('a-galaxy-far-far-away', 'tatooine'), 'got path_to');

$config = Config::Loader->new( file => 't/var/path_to', path_to => 'a-long-time-ago' );

is($config->get->{path_to}, dir('a-long-time-ago', 'tatooine'), 'got path_to');

done_testing;
