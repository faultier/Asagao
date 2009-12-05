use inc::Module::Install;
name 'Asagao';
all_from 'lib/Asagao.pm';

requires 'Any::Moose' => '0.10';
requires 'Path::Dispatcher';
requires 'Plack' => '0.9008';
requires 'Plack::Request';
requires 'Class::Data::Inheritable';
requires 'Getopt::Long';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
auto_install;
WriteAll;
