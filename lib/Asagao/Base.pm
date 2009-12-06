package Asagao::Base;
use Any::Moose;
use Any::Moose 'X::AttributeHelpers';
use Carp;
use Path::Dispatcher;
use Plack::Request;
use Plack::Response;
use UNIVERSAL::require;

our $VERSION = '0.01';

extends( any_moose('::Object'), 'Class::Data::Inheritable' );

__PACKAGE__->mk_classdata( $_ . '_dispatcher' ) foreach (qw(get post put delete));

__PACKAGE__->mk_classdata( 'config' => { template => {}, } );

has req => (
    is       => 'ro',
    isa      => 'Plack::Request',
    required => 1,
);

has res => (
    is      => 'ro',
    isa     => 'Plack::Response',
    lazy    => 1,
    default => sub { Plack::Response->new },
);

has template_mt => (
    is      => 'ro',
    dase    => 'Asagao::Template',
    lazy    => 1,
    builder => '_build_template_mt',
);

sub init_class {
    my $klass = shift;
    my $meta  = any_moose('::Meta::Class')->initialize($klass);
    $meta->superclasses('Asagao::Base') unless $meta->superclasses;

    no strict 'refs';
    no warnings 'redefine';
    *{ $klass . '::meta' } = sub { $meta };
}

sub import {
    my ( $class, ) = @_;
    my $caller = caller;

    return if $class ne 'Asagao::Base';

    strict->import;
    warnings->import;

    init_class($caller);

    any_moose()->import( { into_level => 1 } );

    no strict 'refs';
    no warnings 'redefine';
    *{"$caller\::__ASAGAO__"} = sub {
        use strict;
        my $caller = caller(0);
        __ASAGAO__($caller);
    };
    *{"$caller\::get"}    = sub { _set_handler( $caller, 'get',    @_ ) };
    *{"$caller\::post"}   = sub { _set_handler( $caller, 'post',   @_ ) };
    *{"$caller\::put"}    = sub { _set_handler( $caller, 'put',    @_ ) };
    *{"$caller\::delete"} = sub { _set_handler( $caller, 'delete', @_ ) };
    *{"$caller\::set"} = sub { _set_option( $caller, @_ ) };
}

sub psgi_app {
    my $class = shift;
    return sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        my $app = $class->new( { req => $req } );
        $app->_run();
    };
}

sub start_server {
    my ( $class, %args ) = @_;
    require Plack::Server::Standalone;
    my $server = Plack::Server::Standalone->new(%args);
    $server->run( $class->psgi_app );
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
    my $dispatcher = "$method\_dispatcher";
    $pkg->$dispatcher( Path::Dispatcher->new ) unless $pkg->$dispatcher;
    $pkg->$dispatcher()->add_rule(
        Path::Dispatcher::Rule::Regex->new(
            regex => qr/^$path$/,
            block => sub { $code->(@_) },
        )
    );
}

sub _set_option {
    my ( $pkg, $key, $value ) = @_;
    if ( $key eq 'views' ) {
        $pkg->config->{template}->{include_path} = $value;
    }
}

sub _run {
    my $self      = shift;
    my $dispacher = lc( $self->req->method ) . '_dispatcher';
    my $dispatch  = $self->$dispacher()->dispatch( $self->req->path );
    my $content;
    if ( $dispatch->has_matches ) {
        eval { $content = $dispatch->run($self) };
        if ($@) {
            $self->body('Internal Server Error');
            $self->status(500);
            carp($@);
        }
        else {
            $self->res->body($content);
        }
    }
    else {
        $self->res->body('Not Found');
        $self->res->status(404);
    }
    $self->res->status(200)                unless $self->res->status;
    $self->res->content_type('text/plain') unless $self->res->content_type;
    $self->res->finalize;
}

sub _build_template_mt {
    my $self = shift;
    Asagao::Template::MT->use or croak $@;
    Asagao::Template::MT->new(
        { include_path => $self->config->{template}->{include_path} || ['views'], } );
}

sub mt {
    my ( $self, $tmpl, $args ) = @_;
    my $method = ( $tmpl =~ m{^:[[:alnum:]_\-/]+$} ) ? 'render' : 'render_inline';
    $tmpl =~ s/^:// if $method eq 'render';
    $self->template_mt->$method( $tmpl, $args );
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

'ASAGAO';
