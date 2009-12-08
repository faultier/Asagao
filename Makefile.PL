use inc::Module::Install;
name 'Asagao';
all_from 'lib/Asagao.pm';

requires 'Any::Moose' => '0.10';
requires 'Path::Dispatcher';
requires 'Plack' => '0.9008';
requires 'Plack::Request';
requires 'Class::Data::Inheritable';
requires 'Getopt::Long';

features(
    'Support MicroTemplate template engine' => [
        -default => 1,
        recommends( 'Text::MicroTemplate::Extended' => '0.05' ),
    ],
    'Use Mouse' => [
        -default => 1,
        recommends( 'MouseX::AttributeHelpers' => 0 ),
    ],
    'Use Moose' => [
        -default => 0,
        recommends( 'Moose' => 0 ),
        recommends( 'MooseX::AttributeHelpers' => 0 ),
    ],
);

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
auto_install;
WriteAll;
