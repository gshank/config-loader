use strict;
use warnings;

use Test::More;

use Config::Loader;

$ENV{XYZZY_CONFIG} = "t/var/some_random_file.pl";

my $config = Config::Loader->new( file => 't/var/xyzzy' );

ok($config->get, 'got config from env');
is($config->get->{'Controller::Foo'}->{foo},       'bar', 'got bar');
is($config->get->{'Model::Baz'}->{qux},            'xyzzy', 'got xyzzy');
is($config->get->{'view'},                         'View::TT', 'got view');
is($config->get->{'random'},                        1, 'got random');

$ENV{XYZZY_CONFIG} = "t/var/some_non_existent_file.pl";

$config->reload;

ok($config->get, 'got reloaded config');
is(scalar keys %{ $config->get }, 0, 'no keys from non-existent file');

done_testing;
