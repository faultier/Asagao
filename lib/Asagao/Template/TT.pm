package Asagao::Template::TT;
use utf8;
use Any::Moose;
use Any::Moose 'X::AttributeHelpers';
with 'Asagao::Role::Template';

use Asagao::Config;
use Carp;
use Template;

has template_options => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        +{
            START_TAG => '<%',
            END_TAG   => '%>',
        };
    },
);

has use_cache => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has template_args => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

has infile_templates => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { +{} },
    provides  => {
        get    => 'get_infile_template',
        set    => 'set_infile_template',
        clear  => 'clear_infile_template',
        exists => 'exists_infile_template',
    },
);

has include_path => (
    metaclass => 'Collection::Array',
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    lazy      => 1,
    default   => sub { ['views'] },
    provides  => {
        push   => 'add_path',
        pop    => 'remove_last_path',
        get    => 'get_path',
        set    => 'set_path',
        insert => 'insert_path',
    },
);

has tt => (
    is      => 'ro',
    isa     => 'Template',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Template->new(
            {
                %{ $self->template_options },
                CACHE_SIZE => $self->use_cache ? undef : 0,
                INCLUDE_PATH => $self->include_path,
            }
        );
    },
);

sub render_infile {
    my ( $self, $label, $args ) = @_;
    my $input = $self->get_infile_template($label);
    my $output;
    $self->tt->process( \$input, $args, \$output );
    $output;
}

sub render_file {
    my ( $self, $file, $args ) = @_;
    my $output;
    my $input = "$file.tt";
    $self->tt->process( $input, $args, \$output );
    $output;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
1;
