package Asagao::Role::Singleton;
use Any::Moose '::Role';
use Carp;

sub BUILDARGS {
    my ( $class, %option ) = @_;

    croak "Cannot create instance: ",
      "invalid usage. ", "Use $class->instance() ", "instead of $class->new()"
      if __PACKAGE__ ne ( caller(1) )[0];

    return {%option};
}

sub instance {
    my ( $class, %option ) = @_;

    my $singleton;
    {
        no strict 'refs';
        $singleton = \do { ${ $class . '::Singleton' } };
    }

    if ( defined $$singleton ) {
        while ( my ( $attribute, $value ) = each %option ) {
            $$singleton->$attribute($value);
        }
    }
    else {
        $$singleton = $class->new(%option);
    }

    return $$singleton;
}

1;
