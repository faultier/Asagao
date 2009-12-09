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

has _template => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

sub template_include_path {
    my ( $self, $value ) = @_;
    if ($value) {
        croak 'include_path required ArrayRef' unless ref($value) eq 'ARRAY';
        $self->_template->{include_path} = $value;
    }
    $self->_template->{include_path} ||= [];
}

sub template_args {
    my ( $self, $value ) = @_;
    if ($value) {
        croak 'args required HashRef' unless ref($value) eq 'HASH';
        $self->_template->{args} = $value;
    }
    $self->_template->{args} ||= {};
}

sub template_use_cache {
    my ( $self, $value ) = @_;
    if ($value) {
        $self->_template->{use_cache} = $value;
    }
    $self->_template->{use_cache};
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
1;
