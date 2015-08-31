use inc::Module::Install;

name 'Config-Loader';
all_from 'lib/Config/Loader.pm';

resources repository => 'http://github.com/gshank/config-loader/tree/master';

build_requires 'Test::More';
build_requires 'Test::Most';

requires 'Config::Any';
requires 'Data::Visitor' => 0.24;
requires 'Hash::Merge::Simple';
requires 'List::MoreUtils';
requires 'Moose';
requires 'Sub::Install';
requires 'Clone';

if (-e 'inc/.author') {
    my $all_from = join '/', 'lib', split m/-/, name . '.pm';
    `perldoc -tF $all_from > README` if ! -e 'README' || (stat $all_from)[9] > (stat 'README')[9];
}

tests_recursive 't';

auto_install;

WriteAll;
