package Asagao::Base;

use Asagao::Class;
use Path::Dispatcher;
use Plack::Request;
use Plack::Response;
extends Any::Moose::any_moose('::Object');
extends 'Class::Data::Inheritable';

foreach my $meth (qw(get post put delete)) {
    __PACKAGE__->mk_classdata( "$meth\_dispatcher" => Path::Dispatcher->new );
}

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

sub psgi_app {
    my $class = shift;
    return sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        my $app = $class->new( { req => $req } );
        $app->run();
    };
}

sub run {
    my $self      = shift;
    my $dispacher = lc( $self->req->method ) . '_dispatcher';
    my $dispatch  = $self->$dispacher()->dispatch( $self->req->path );
    my $content   = $dispatch->run($self);
    $self->res->body($content) if $content;
    $self->res->status(200);
    $self->res->content_type('text/plain');
    $self->res->finalize;
}

sub start_server {
    my ( $class, %args ) = @_;
    require Plack::Server::Standalone;
    my $server = Plack::Server::Standalone->new( %args );
    $server->run( $class->psgi_app );
}

__ASAGAO__
