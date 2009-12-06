package Asagao::Template::MT;
use Any::Moose;
use Any::Moose 'X::AttributeHelpers';
with 'Asagao::Template';

use Carp;
use Text::MicroTemplate;
use Text::MicroTemplate::Extended;

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
    default => 0,
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

sub render_inline {
    my ( $self, $tmpl, $args ) = @_;
    $self->set_infile_template( "inline::$tmpl" => $tmpl );
    $self->render_infile( "inline::$tmpl", $args );
}

sub render_infile {
    my ( $self, $label, $args ) = @_;
    my $cache_key;
    my $renderer;
    my %template_args = %{ $self->template_args };
    foreach my $key ( keys %{ $args || {} } ) {
        $template_args{$key} = $args->{$key};
    }
    if ( $self->use_cache ) {
        $cache_key = join( ':', 'infile', $label, keys(%template_args) );
        $renderer = $self->get_cache($cache_key);
    }
    unless ($renderer) {
        my $mt = Text::MicroTemplate->new( %{ $self->template_options },
            template => $self->get_infile_template($label), );
        my $code   = $mt->code;
        my $setter = '';
        $setter .= join( '', map { "my \$$_ = shift;" } keys(%template_args) );
        $renderer = eval "sub { $setter; $code->() }" or croak $@; ## no critic
        $self->set_cache( $cache_key => $renderer ) if $self->use_cache;
    }
    $renderer->( values(%template_args) );
}

sub render_file {
    my ( $self, $file, $args ) = @_;
    my $mt;
    my $cache_key;
    my %template_args = ref($args) eq 'HASH' ? %$args : ();
    if ( $self->use_cache ) {
        $cache_key = join( ':', $file, keys %template_args );
        $mt = $self->get_cache($cache_key);

    }
    if ($mt) {
        foreach my $key ( keys %template_args ) {
            $mt->template_args->{$key} = $template_args{$key};
        }
    }
    else {
        $mt = Text::MicroTemplate::Extended->new(
            %{ $self->template_options },
            use_cache     => $self->use_cache,
            include_path  => $self->include_path,
            template_args => { %{ $self->template_args }, %template_args },
        );
        $self->set_cache( $cache_key => $mt ) if $self->use_cache;
    }
    return $mt->render($file);
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
'ASAGAO';
