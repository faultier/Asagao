package Asagao::Context;
use utf8;
use Any::Moose;

has req => (
    is       => 'ro',
    isa      => 'Plack::Request',
    required => 1,
    handles  => [qw(params)],
);

has res => (
    is      => 'ro',
    isa     => 'Plack::Response',
    lazy    => 1,
    default => sub { Plack::Response->new },
    handles => [qw(body status content_type status redirect finalize)],
);

has app => (
    is       => 'ro',
    isa      => 'Asagao::Base',
    required => 1,
    handles  => [qw(mt)],
    weak_ref => 1,
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;
1;
