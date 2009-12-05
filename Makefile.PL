use inc::Module::Install;
name 'Asagao';
all_from 'lib/Asagao.pm';

requires 'Any::Moose';
requires 'Plack';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
