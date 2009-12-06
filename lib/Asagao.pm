package Asagao;
use Any::Moose;
use Asagao::Default;

our $VERSION = '0.01';

sub import {
    my ( $class, $target ) = @_;
    my $caller = caller;

    strict->import;
    warnings->import;

    any_moose()->import( { into_level => 1 } );

    no strict 'refs';
    no warnings 'redefine';
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
    if ( $_[0] eq $0 ) {
        require Getopt::Long;
        Getopt::Long::GetOptions(
            'host=s'               => \my $host,
            'port=i'               => \my $port,
            'timeout=i'            => \my $timeout,
            'max-keepalive-reqs=i' => \my $max_keepalive_reqs,
            'keepalive-timeout'    => \my $keepalive_timeout
        );
        Asagao::Default->start_server(
            host                => $host               || '0.0.0.0',
            port                => $port               || 4423,
            timeout             => $timeout            || 300,
            'max-keealive-reqs' => $max_keepalive_reqs || 1,
            'keepalive-timeout' => $keepalive_timeout  || 2,
        );
        exit 0;
    }
    Asagao::Default->psgi_app;
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
