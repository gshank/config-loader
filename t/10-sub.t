use strict;
use warnings;

use Test::Most;

use Path::Class;
use Config::Loader;

{
    my $config = Config::Loader->new(
        file => 't/var/substitute',
        substitute => {
            literal => sub {
                return "Literally, $_[1]!";
            },
            two_plus_two => sub {
                return 2 + 2;
            },
        },
     );
    ok( $config->get, 'got config with substitutes' );

    is( $config->get->{default}, file( 'a-galaxy-far-far-away', '' ), 'got default' ); # Not dir because path_to treats a non-existent directory as a file
    is( $config->get->{default_override}, "Literally, this!", 'got default override' );
    is( $config->get->{original}, 4, 'got original' );
    is( $config->get->{original_embed}, "2 + 2 = 4", 'got original embed' );
}

{
    my $path = dir(qw/ t var /)->absolute;
    my $config = Config::Loader->new( file => "$path/substitute-path-to",);
    ok( $config->get, 'got config' );

    is( $config->get->{default}, "$path", 'got default' );
    is( $config->get->{template}, $path->file( 'root/template' ), 'got template' );
}

done_testing;
