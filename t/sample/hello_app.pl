#!/usr/bin/env perl
use Asagao;

template infile => sub {
    '<%= $name %> is a sloth.';
};

get '/' => sub {
    'Hello, Asagao World!';
};

get '/in-file-template' => sub {
    my $self = shift;
    $self->render( ':infile', { name => 'Taro' } );
};

get '/wildcard/*' => sub {
    'Wildcard Ok!';
};

get '/namedparam/:name' => sub {
    my $self = shift;
    $self->render( '<%= $name %>', { name => $self->param('name') });
};

post qr{^/regex/[0-9]$} => sub {
    my $self = shift;
    'regex!';
};

not_found {
    return 'Not Found!';
};

__ASAGAO__
