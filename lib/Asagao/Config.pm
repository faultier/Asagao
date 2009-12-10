package Asagao::Config;
use utf8;
use Any::Moose;
use Carp;
with 'Asagao::Role::Singleton';

has base_path => (
    is  => 'rw',
    isa => 'Str',
);

has static_path => (
    is  => 'rw',
    isa => 'Str',
);

has template_class => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'Asagao::Template::MT' },
);

has template_include_path => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { +[qw(views)] },
);

has template_args => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} },
);

has template_use_cache => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

no Any::Moose;
__PACKAGE__->meta->make_immutable;
1;
