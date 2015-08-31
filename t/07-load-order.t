use strict;
use warnings;

use Test::More;

plan skip_all => "Config::General is required for this test" unless eval "require Config::General;";

use Config::Loader;

my $config = Config::Loader->new( file => 't/var/order/xyzzy' );

ok($config->get, 'got config from Config::General');
is($config->get->{'last'}, 'local_pl', 'got last');
is($config->get->{$_}, 1, "got $_") for ('pl', 'perl', 'local_pl', 'local_perl', 'cnf', 'local_cnf', 'conf', 'local_conf');

done_testing;
