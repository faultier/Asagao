package Asagao::Context;

use Any::Moose;

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

has app => (
    is       => 'ro',
    isa      => 'Asagao::Base',
    required => 1,
    handles  => [qw(mt)],
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;
1;
