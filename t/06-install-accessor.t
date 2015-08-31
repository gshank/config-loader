use strict;
use warnings;

use Test::More;

use Config::Loader;

my $config = Config::Loader->new( file => 't/var/xyzzy_catalyst', install_accessor_into => 'A::Random::Package' );

ok(!Xyzzy::Catalyst->can("config"), 'some package can\t config');
ok(A::Random::Package->config, 'install_accessor_into can config');
$config = A::Random::Package->config;
ok($config, 'got config');
is($config->{'Controller::Foo'}->{foo},       'bar', 'got foo');
is($config->{'Model::Baz'}->{qux},            'xyzzy', 'got qux');
is($config->{'view'},                         'View::TT', 'got view');

$config = Config::Loader->new( file => 't/var/xyzzy_catalyst', install_accessor_into => 'Xyzzy::Catalyst' );

ok(Xyzzy::Catalyst->config, 'got config from name with install_accessor => 1');
$config = Xyzzy::Catalyst->config;
ok($config, 'got config');
is($config->{'Controller::Foo'}->{foo},       'bar', 'got foo');
is($config->{'Model::Baz'}->{qux},            'xyzzy', 'got qux');
is($config->{'view'},                         'View::TT', 'got view');

done_testing;
