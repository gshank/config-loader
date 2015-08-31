use strict;
use warnings;

use Test::More;

use Config::Loader;

eval {
    delete $ENV{$_} for ('CATALYST_CONFIG_LOCAL_SUFFIX');
};

$ENV{CATALYST_CONFIG} = "t/var/some_random_file.pl";

my $config = Config::Loader->new( file => 't/var/xyzzy', env_lookup => 'CATALYST' );

ok($config->get, 'got config');
is($config->get->{'Controller::Foo'}->{foo},       'bar', 'got foo');
is($config->get->{'Model::Baz'}->{qux},            'xyzzy', 'got qux');
is($config->get->{'view'},                         'View::TT', 'got view');
is($config->get->{'random'},                        1, 'got random');

$ENV{XYZZY_CONFIG} = "t/var/xyzzy.pl";

$config = Config::Loader->new( file => 't/var/xyzzy', env_lookup => [qw/CATALYST/]);

ok($config->get, 'got config');
is($config->get->{'Controller::Foo'}->{foo},       'bar', 'got foo');
is($config->get->{'Controller::Foo'}->{new},       'key', 'got new');
is($config->get->{'Model::Baz'}->{qux},            'xyzzy', 'got qux');
is($config->get->{'Model::Baz'}->{another},        'new key', 'got another');
is($config->get->{'view'},                         'View::TT::New', 'got view');
is($config->get->{'foo_sub'},                      '__foo(x,y)__', 'got foo sub' );
is($config->get->{'literal_macro'},                '__DATA__', 'got macro');

done_testing;
