use strict;
use warnings;

use Test::Most;

use Config::Loader;


{
    my $config = Config::Loader->new( file => "t/var/some_random_file.pl");

    ok($config->get, 'got config');
    is($config->get->{'Controller::Foo'}->{foo},       'bar', 'got foo');
    is($config->get->{'Model::Baz'}->{qux},            'xyzzy', 'got qux');
    is($config->get->{'view'},                         'View::TT', 'got view');
    is($config->get->{'random'},                        1, 'got random');
}

{

    my $config;

    $config = Config::Loader->new( file => "t/var/order/../dotdot",);
    ok($config->load, 'Load a config from a directory path ending with ../');
    cmp_deeply( $config->get, { test => 'paths ending with ../', }, 'got test' );

    $config = Config::Loader->new( file => "t/var/order/xyzzy.cnf");
    cmp_deeply( $config->get, {
        cnf => 1,
        last => 'local_cnf',
        local_cnf => 1,
    }, 'correct config using path' );

    $config = Config::Loader->new( file => "t/var/order/xyzzy.cnf", no_local => 1);
    cmp_deeply( $config->get, {
        cnf => 1,
        last => 'cnf',
    }, 'correct config using no_local' );

    $config = Config::Loader->new( file => "t/var/file-does-not-exist.cnf");
    cmp_deeply( $config->get, { }, 'no config for non-existent file' );
}

done_testing;
