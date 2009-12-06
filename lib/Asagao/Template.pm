package Asagao::Template;
use Any::Moose '::Role';

requires 'render_inline';
requires 'render_infile';
requires 'render_file';

sub render {
    my ( $self, $name, $args ) = @_;
    my $result;
    if ( $self->exists_infile_template($name) ) {
        $result = $self->render_infile($name, $args);
    }
    else {
        $result = $self->render_file($name, $args);
    }
    return $result;
}

'ASAGAO';
