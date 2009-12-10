package Asagao::Template::MT;
use utf8;
use Any::Moose;
use Any::Moose 'X::AttributeHelpers';
with 'Asagao::Role::Template';

use Asagao::Config;
use Carp;
use Text::MicroTemplate;
use Text::MicroTemplate::Extended;

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
            tag_start  => '<%',
            tag_end    => '%>',
            line_start => '%',
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

has cache => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { +{} },
    provides  => {
        get   => 'get_cache',
        set   => 'set_cache',
        clear => 'clear_cache',
        empty => 'is_not_cache_empty',
    },
);

has mt => (
    is         => 'ro',
    isa        => 'Text::MicroTemplate::Extended',
    lazy_build => 1,
);

sub _build_mt {
    my $self = shift;
    Text::MicroTemplate::Extended->new(
        %{ $self->template_options },
        use_cache    => $self->use_cache,
        include_path => $self->config->template_include_path,
    );
}

sub render_inline {
    my ( $self, $tmpl, $args, $label ) = @_;
    my $cache_key;
    my $renderer;
    my %template_args = %{ $self->config->template_args };
    foreach my $key ( keys %{ $args || {} } ) {
        $template_args{$key} = $args->{$key};
    }
    if ( $self->use_cache && $label ) {
        $cache_key = join( ':', $label, keys(%template_args) );
        $renderer = $self->get_cache($cache_key);
    }
    unless ($renderer) {
        my $mt     = Text::MicroTemplate->new( %{ $self->template_options }, template => $tmpl, );
        my $code   = $mt->code;
        my $setter = '';
        $setter .= join( '', map { "my \$$_ = shift;" } keys(%template_args) );
        $renderer = eval "sub { $setter; $code->() }" or croak $@;    ## no critic
        $self->set_cache( $cache_key => $renderer ) if $self->use_cache;
    }
    $renderer->( values(%template_args) );
}

sub render_file {
    my ( $self, $file, $args ) = @_;
    my %template_args = ref($args) eq 'HASH' ? %$args : ();
    my $mt = $self->mt;
    $mt->template_args( { %{ $self->config->template_args }, %template_args } );
    return $mt->render($file);
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
'ASAGAO';
