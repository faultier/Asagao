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
    $self->mt( ':infile', { name => 'Taro' } );
};

post qr{/regex/.*} => sub {
    my $self = shift;
    'regex!';
};

not_found {
    return 'Not Found!';
};

__ASAGAO__
