#!/usr/bin/env perl
use Asagao;

get '/' => sub {
    'Hello, Asagao World!';
};

__ASAGAO__
