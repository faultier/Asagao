use Plack::Test;
use Test::More;
use HTTP::Request::Common;

my $app = require 't/sample/hello_app.pl';

test_psgi
  app    => $app,
  client => sub {
    my $cb  = shift;
    my $res = $cb->( GET 'http://localhost/' );
    is $res->code,      200;
    like $res->content, qr/Hello, Asagao World!/;
  };

test_psgi
  app    => $app,
  client => sub {
    my $cb  = shift;
    my $res = $cb->( GET 'http://localhost/in-file-template' );
    is $res->code,      200;
    like $res->content, qr/Taro is a sloth/;
  };

test_psgi
  app    => $app,
  client => sub {
    my $cb = shift;
    is $cb->( POST 'http://localhost/regex/hoge' )->code, 200;
    is $cb->( POST 'http://localhost/regex/fuga' )->code, 200;
    is $cb->( POST 'http://localhost/hoge' )->code,       404;
  };

done_testing;
