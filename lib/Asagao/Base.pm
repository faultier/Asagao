package Asagao::Base;

use Asagao::Class;
extends Any::Moose::any_moose('::Object');

sub psgi_app {
    my $class = shift;
    return sub {
        my $env = shift;
        my $app = $class->new;
        $app->run($env);
    };
}

sub run {
    return [ 200, [ 'Content-Type' => 'text/plain' ], ['Hello, Asagao World!'], ];
}

__ASAGAO__
