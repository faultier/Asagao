package Asagao;
use Any::Moose;
use Plack::Server::Standalone;
our $VERSION = '0.01';

use Asagao::Default;

sub import {
    my $class  = shift;
    my $caller = caller;

    strict->import;
    warnings->import;

    any_moose()->import( { into_level => 1 } );

    no strict 'refs';
    *{"$caller\::__ASAGAO__"} = sub {
        use strict;
        my ( $pkg, $file ) = caller;
        __ASAGAO__($file);
    };
    *{"$caller\::get"}    = sub { Asagao::Default::get(@_) };
    *{"$caller\::post"}   = sub { Asagao::Default::post(@_) };
    *{"$caller\::put"}    = sub { Asagao::Default::put(@_) };
    *{"$caller\::delete"} = sub { Asagao::Default::delete(@_) };
}

sub __ASAGAO__ {
    my $file = shift;
    my $app  = Asagao::Default->psgi_app;
    if ( $file eq $0 ) {
        my $server = Plack::Server::Standalone->new;
        $server->run($app);
    }
    else {
        return $app;
    }
}

1;

__END__

=head1 NAME

Asagao -

=head1 SYNOPSIS

  use Asagao;

  get index => sub {
    'Hello, Asagao world!';
  };

  __ASAGAO__

=head1 DESCRIPTION

Asagao is simple web application framework, like Sinatra.

=head1 AUTHOR

faultier E<lt>faultier@namakemon.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
