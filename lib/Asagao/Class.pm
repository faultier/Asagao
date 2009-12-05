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

    *{"$caller\::get"}    = sub { _set_handler( $caller, 'get',    @_ ) };
    *{"$caller\::post"}   = sub { _set_handler( $caller, 'post',   @_ ) };
    *{"$caller\::put"}    = sub { _set_handler( $caller, 'put',    @_ ) };
    *{"$caller\::delete"} = sub { _set_handler( $caller, 'delete', @_ ) };
}

sub __ASAGAO__ {
    my $caller = shift;
    Any::Moose::unimport;
    $caller->meta->make_immutable( inline_destructor => 1 );
    "ASAGAO";
}

sub _set_handler {
    my ( $pkg, $method, $path, $code ) = @_;
    my ($name) = $path =~ m/^\/(.*)/;
    $name ||= 'index';
    $name =~ s/\//_/g;
    $name = lc($name);
    my $handler    = "$method\_$name";
    my $dispatcher = "$method\_dispatcher";
    $pkg->meta->add_method( $handler, $code );
    $pkg->$dispatcher()->add_rule(
        Path::Dispatcher::Rule::Regex->new(
            regex => qr/^$path/,
            block => sub { shift->$handler() },
        )
    );
}

1;
