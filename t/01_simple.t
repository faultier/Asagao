use Plack::Test;
use Test::More;
use HTTP::Request::Common;

my $app = require 't/sample/hello_app.pl';

test_psgi app => $app, client => sub {
    my $cb = shift;
    my $res = $cb->(GET 'http://localhost/');
    is   $res->code,    200;
    like $res->content, qr/Hello, Asagao World!/;
};

done_testing;
