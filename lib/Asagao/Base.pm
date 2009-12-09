package Asagao::Base;
use utf8;
use Any::Moose;
use Any::Moose 'X::AttributeHelpers';
use Asagao::Config;
use Asagao::Context;
use Carp;
use Path::Dispatcher;
use Plack::Request;
use Plack::Response;
use UNIVERSAL::require;

our $VERSION = '0.01';

extends( any_moose('::Object'), 'Class::Data::Inheritable' );
__PACKAGE__->mk_classdata( $_ . '_dispatcher' ) foreach qw(get post);
__PACKAGE__->mk_classdata( infile_templates => {} );

has template_mt => (
    is         => 'ro',
    lazy_build => 1,
);

has template_tt => (
    is         => 'ro',
    lazy_build => 1,
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
    my $class  = shift;
    my $caller = caller;

    return unless $class eq 'Asagao::Base';

    strict->import;
    warnings->import;
    utf8->import;

    init_class($caller);

    any_moose()->import( { into_level => 1 } );

    no strict 'refs';
    no warnings 'redefine';
    *{"$caller\::__ASAGAO__"} = sub {
        use strict;
        my $caller = caller(0);
        __ASAGAO__($caller);
    };
    *{"$caller\::get"}  = sub { _set_handler( $caller, 'get',  @_ ) };
    *{"$caller\::post"} = sub { _set_handler( $caller, 'post', @_ ) };
    *{"$caller\::set"} = sub { _set_option( $caller, @_ ) };
    *{"$caller\::template"} = sub { _set_template( $caller, @_ ) };
    *{"$caller\::not_found"} = sub (&) {
        my $code = shift;
        $caller->meta->add_method(
            handle_not_found => sub {
                my ( $self, $context ) = @_;
                my $body = $code->($context);
                $context->res->body($body);
                $context->res->status(404) unless $context->res->status;
            }
        );
    };
}

sub psgi_app {
    my $class    = shift;
    my $app      = $class->new(@_);
    my $config   = Asagao::Config->instance;
    my $psgi_app = sub {
        my $env = shift;
        if ( my $base_path = $config->base_path ) {
            $env->{PATH_INFO} =~ s/^$base_path//;
        }
        $app->run($env);
    };
    if ( $config->static_path ) {
        Plack::Middleware::Static->use or croak $@;
        $psgi_app = Plack::Middleware::Static->wrap(
            $psgi_app,
            path => qr{^/(images|js|css)/},
            root => $config->static_path,
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
            my ( $self, $context ) = @_;
            $context->res->status(404);
            $context->res->body('Not Found');
        }
    );
    Any::Moose::unimport;

    #   $caller->meta->make_immutable( inline_destructor => 1 );
    "ASAGAO";
}

sub _configure {
    my $code = shift;
    $code->( Asagao::Config->instance );
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
        my @keys;
        @tokens = map {
            my $token = $_;
            if ( $token =~ /^:([[:alnum:]]+)$/ ) {
                $token = qr{^.+$};
                push @keys, $1;
            }
            elsif ( $token =~ /\*/ ) {
                $token =~ s/\*/.*/g;
                $token =~ s/\./\./g;
                $token = qr{^$token$};
                push @keys, '_ignore';
            }
            else {
                push @keys, '_ignore';
            }
            $token;
        } grep { $_ && $_ ne '/' } @tokens;
        $dispatcher->add_rule(
            Path::Dispatcher::Rule::Tokens->new(
                tokens    => \@tokens,
                delimiter => '/',
                block     => sub {
                    my ( $context, @args ) = @_;
                    for ( my $i = 1 ; $i <= scalar(@keys) ; $i++ ) {
                        my $key = $keys[ $i - 1 ];
                        next if $key eq '_ignore';
                        eval "\$context->req->param($key => \$$i)";    ## no critic
                    }
                    $code->( $context, @args );
                },
            )
        );
    }
}

sub _set_option {
    my ( $pkg, $key, $value ) = @_;
    my $class = ref($pkg) || $pkg;
    my $config = Asagao::Config->instance;
    if ( $key eq 'views' ) {
        $config->template_include_path($value);
    }
    elsif ( $key eq 'static' ) {
        $config->static_path($value);
    }
    elsif ( $key eq 'base_path' ) {
        $config->base_path($value);
    }
}

sub _set_template {
    my ( $pkg, $label, $generator ) = @_;
    my $class = ref($pkg) || $pkg;
    $class->infile_templates->{$label} = $generator->();
}

sub BUILD {
    my $self   = shift;
    my $config = Asagao::Config->instance;
    $config->template_include_path( ['views'] ) unless $config->template_include_path;
    my $tmpl_args = $config->template_args || {};
    $config->template_args(
        {
            %$tmpl_args,
            PLACK_VERSION  => $Plack::VERSION,
            ASAGAO_VERSION => $Asagao::Base::VERSION,
        }
    );
}

sub run {
    my ( $self, $env ) = @_;
    if ( $env->{REQUEST_METHOD} eq 'OPTIONS' ) {
        return [ 200, [ Allow => 'GET, HEAD, POST, OPTIONS' ], [] ];
    }
    else {
        my $context = Asagao::Context->new( { app => $self, req => Plack::Request->new($env) } );
        $self->dispatch($context);
        $context->status(200)               unless $context->status;
        $context->content_type('text/html') unless $context->content_type;
        return $context->finalize;
    }
}

sub dispatch {
    my ( $self, $context ) = @_;
    my $request_method = $context->req->method;
    my $disp_attr      = lc($request_method) . '_dispatcher';
    $disp_attr = 'get_dispatcher' if $request_method eq 'HEAD';
    unless ( $self->can($disp_attr) ) {
        $context->body('Method Not Allowd');
        $context->status(405);
        return;
    }
    my $dispatcher = $self->$disp_attr();
    local $@;
    eval {
        my $content;
        if ($dispatcher) {
            my $dispatch = $dispatcher->dispatch( $context->req->env->{PATH_INFO} );
            if ( $dispatch->has_matches ) {
                $content = $dispatch->run($context);
            }
        }
        if ($content) {
            $context->body($content);
        }
        else {
            $self->handle_not_found($context);
        }
    };
    if ($@) {
        $context->body('Internal Server Error');
        $context->status(500);
        carp($@);
    }
}

sub _build_template_mt {
    my $self   = shift;
    my $config = Asagao::Config->instance;
    Asagao::Template::MT->use or croak $@;
    Asagao::Template::MT->new( { config => $config, } );
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
    my $content = $self->template_mt->$method( $tmpl, $args );
    utf8::encode($content);
    $content;
}

sub _build_template_tt {
    my $self   = shift;
    my $config = Asagao::Config->instance;
    Asagao::Template::TT->use or croak $@;
    Asagao::Template::TT->new(
        {
            include_path => $config->template_include_path,
            template_args =>
              { %{ $config->template_args || {} }, base_path => $config->base_path, },
        }
    );
}

sub tt {
    my ( $self, $tmpl, $args ) = @_;
    my $method = ( $tmpl =~ m{^:[[:alnum:]_\-/]+$} ) ? 'render' : 'render_inline';
    if ( $method eq 'render' ) {
        $tmpl =~ s/^://;
        if ( $self->infile_templates->{$tmpl}
            && !$self->template_tt->exists_infile_template($tmpl) )
        {
            $self->template_tt->set_infile_template( $tmpl => $self->infile_templates->{$tmpl} );
        }
    }
    my $content = $self->template_tt->$method( $tmpl, $args );
    utf8::encode($content);
    $content;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
