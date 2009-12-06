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
__PACKAGE__->mk_classdata( base_path        => '' );
__PACKAGE__->mk_classdata( infile_templates => {} );
__PACKAGE__->mk_classdata( config           => { template => { include_path => ['views'], }, } );

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
    my $class = shift;
    my $caller = caller;

    return unless $class eq 'Asagao::Base';

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
    *{"$caller\::template"} = sub { _set_template( $caller, @_ ) };
    *{"$caller\::not_found"} = sub (&) {
        my $code = shift;
        $caller->meta->add_method(
            handle_not_found => sub {
                my $self = shift;
                my $body = $code->();
                $self->res->body($body);
                $self->res->status(404) unless $self->res->status;
            }
        ) unless $caller->meta->has_method('handle_not_found');
    };
}

sub psgi_app {
    my $class    = shift;
    my $psgi_app = sub {
        my $env = shift;
        if ( my $base_path = $class->base_path ) {
            $env->{PATH_INFO} =~ s/^$base_path//;
        }
        my $req = Plack::Request->new($env);
        my $app = $class->new( { req => $req } );
        $app->_run();
    };
    if ( $class->config->{static} ) {
        $psgi_app = Plack::Middleware::Static->wrap(
            $psgi_app,
            path => qr{^/(images|js|css)/},
            root => $class->config->{static},
        );
    }
    $psgi_app;
}

sub start_server {
    my ( $class, %args ) = @_;
    require Plack::Server::Standalone;
    my $server = Plack::Server::Standalone->new(%args);
    $server->run( $class->psgi_app );
}

sub __ASAGAO__ {
    my $caller = shift;
    no strict 'refs';
    $caller->meta->add_method(
        handle_not_found => sub {
            my $self = shift;
            $self->res->status(404);
            $self->res->body('Not Found');
        }
    ) unless $caller->meta->has_method('handle_not_found');
    Any::Moose::unimport;
    $caller->meta->make_immutable( inline_destructor => 1 );
    "ASAGAO";
}

sub _set_handler {
    my ( $pkg, $method, $path, $code ) = @_;
    my $class = ref($pkg) || $pkg;
    my $disp_attr = "$method\_dispatcher";
    $class->$disp_attr( Path::Dispatcher->new ) unless $class->$disp_attr;
    my $dispatcher = $class->$disp_attr();
    $path = qr{^/(?:index(?:\.[[:alnum:]]+)?)?$} if $path eq '/';
    if ( ref($path) eq 'Regexp' ) {
        $dispatcher->add_rule(
            Path::Dispatcher::Rule::Regex->new(
                regex => $path,
                block => sub { $code->(@_) },
            )
        );
    }
    else {
        my ($name) = $path =~ m/^\/(.*)/;
        my @tokens = split( '/', $name );
        $dispatcher->add_rule(
            Path::Dispatcher::Rule::Tokens->new(
                tokens    => \@tokens,
                delimiter => '/',
                block     => sub { $code->(@_) },
            )
        );
    }
}

sub _set_option {
    my ( $pkg, $key, $value ) = @_;
    my $class = ref($pkg) || $pkg;
    if ( $key eq 'views' ) {
        $class->config->{template}->{include_path} = $value;
    }
    elsif ( $key eq 'static' ) {
        $class->config->{static} = $value;
    }
    elsif ( $key eq 'base_path' ) {
        $class->base_path($value);
    }
}

sub _set_template {
    my ( $pkg, $label, $generator ) = @_;
    my $class = ref($pkg) || $pkg;
    $class->infile_templates->{$label} = $generator->();
}

sub _run {
    my $self       = shift;
    my $disp_attr  = lc( $self->req->method ) . '_dispatcher';
    my $dispatcher = $self->$disp_attr();
    local $@;
    eval {
        my $content;
        if ($dispatcher) {
            my $dispatch = $dispatcher->dispatch( $self->req->env->{PATH_INFO} );
            if ( $dispatch->has_matches ) {
                $content = $dispatch->run($self);
            }
        }
        if ($content) {
            $self->res->body($content);
        }
        else {
            $self->handle_not_found;
        }
    };
    if ($@) {
        $self->res->body('Internal Server Error');
        $self->res->status(500);
        carp($@);
    }
    $self->res->status(200)               unless $self->res->status;
    $self->res->content_type('text/html') unless $self->res->content_type;
    $self->res->finalize;
}

sub _build_template_mt {
    my $self = shift;
    Asagao::Template::MT->use or croak $@;
    Asagao::Template::MT->new( { include_path => $self->config->{template}->{include_path} } );
}

sub mt {
    my ( $self, $tmpl, $args ) = @_;
    my $method = ( $tmpl =~ m{^:[[:alnum:]_\-/]+$} ) ? 'render' : 'render_inline';
    if ( $method eq 'render' ) {
        $tmpl =~ s/^://;
        if ( $self->infile_templates->{$tmpl}
            && !$self->template_mt->exists_infile_template($tmpl) )
        {
            $self->template_mt->set_infile_template( $tmpl => $self->infile_templates->{$tmpl} );
        }
    }
    $self->template_mt->$method( $tmpl, $args );
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
