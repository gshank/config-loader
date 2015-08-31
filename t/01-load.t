use strict;
use warnings;
use Test::More;

use Config::Loader;

=comment
xyzzy.pl
{   name              => 'TestApp',
    view              => 'View::TT',
    'Controller::Foo' => { foo => 'bar' },
    'Model::Baz'      => { qux => 'xyzzy' },
    foo_sub           => '__foo(x,y)__',
    literal_macro     => '__literal(__DATA__)__',
}

xyzzy_local.pl

{   view              => 'View::TT::New',
    'Controller::Foo' => { new => 'key' },
    'Model::Baz' => { 'another' => 'new key' },
}

=cut

my $config = Config::Loader->new( file => 't/var/xyzzy' );
$DB::single=1;
my @files = $config->get_files;

ok($config->get, 'got config');
is($config->get->{'Controller::Foo'}->{foo},         'bar', 'got foo');
is($config->get->{'Controller::Foo'}->{new},         'key', 'got key');
is($config->get->{'Model::Baz'}->{qux},              'xyzzy', 'got xyzzy');
is($config->get->{'Model::Baz'}->{another},          'new key', 'got new key');
is($config->get->{'view'},                           'View::TT::New', 'got View::TT::New');
is($config->get->{'foo_sub'},                        '__foo(x,y)__', 'got foo(x,y)');
is($config->get->{'literal_macro'},                  '__DATA__', 'got __DATA__');

done_testing;
