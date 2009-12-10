package Asagao::Template::TT;
use utf8;
use Any::Moose;
use Any::Moose 'X::AttributeHelpers';
with 'Asagao::Role::Template';

use Asagao::Config;
use Carp;
use Template;

has config => (
    is      => 'ro',
    isa     => 'Asagao::Config',
    default => sub { Asagao::Config->instance },
);

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
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->config->template_use_cache;
    },
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

has tt => (
    is         => 'ro',
    isa        => 'Template',
    lazy_build => 1,
);

sub _build_tt {
    my $self = shift;
    Template->new(
        {
            %{ $self->template_options },
            CACHE_SIZE => $self->use_cache ? undef : 0,
            INCLUDE_PATH => $self->config->template_include_path,
        }
    );
}

sub render_inline {
    my ( $self, $input, $args ) = @_;
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
