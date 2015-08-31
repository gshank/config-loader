use strict;
use warnings;

use Test::Most;

use Config::Loader;

BEGIN {
    skip => 'Config::General required'
       unless eval "require Config::General";
}

{
    my $config = Config::Loader->new( file => 't/var/some_random_file.pl' );

    ok( $config->get, 'get some_random_file' );
    ok( keys %{ $config->get }, 'correct keys in config' );
    ok( $config->files_found, 'returns found' );
    cmp_deeply( $config->files_found, bag( 't/var/some_random_file.pl' ), 'found has right contents' );
}

{
    my $config = Config::Loader->new( file => 't/var/xyzzy' );
    ok( $config->get, 'get config from xyzzy' );
    ok( keys %{ $config->get }, 'has keys' );
    ok( $config->files_found, 'contains found' );
    cmp_deeply( $config->files_found, bag( 't/var/xyzzy.pl', 't/var/xyzzy_local.pl' ),
       'found has right contents' );
}

{
    my $config = Config::Loader->new( file => 't/var/missing-file.pl' );

    ok( $config->get, 'got missing file' );
    cmp_deeply( $config->get, {}, 'empty config' );
    ok( ! scalar @{$config->files_found}, 'nothing found' );
}

{
    my $config = Config::Loader->new( file => 't/var/some_random_file.pl' );
    $config->get_files;

    ok( $config->get, 'got config from random file' );
    ok( $config->files_found, 'got found' );
    ok( keys %{ $config->get }, 'got keys' );
    cmp_deeply( $config->files_found, bag( 't/var/some_random_file.pl' ), 'found is correct' );
}

done_testing;
