package Asagao::Class;

use Any::Moose;

sub import {
    my ( $class, ) = @_;
    my $caller = caller;

    strict->import;
    warnings->import;

    any_moose()->import( { into_level => 1 } );

    no strict 'refs';
    *{"$caller\::__ASAGAO__"} = sub {
        use strict;
        my $caller = caller(0);
        __ASAGAO__($caller);
    };

    *{"$caller\::get"}  = \&_get;
    *{"$caller\::post"} = \&_post;
    *{"$caller\::put"}  = \&_put;
    *{"$caller\::delete"}  = \&_delete;
}

sub __ASAGAO__ {
    my $caller = shift;
    Any::Moose::unimport;
    $caller->meta->make_immutable( inline_destructor => 1 );
    "ASAGAO";
}

sub _get {
}

sub _post {
}

sub _put {
}

sub _delete {
}

1;
