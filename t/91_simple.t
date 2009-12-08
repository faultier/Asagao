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
    is $cb->( GET 'http://localhost/wildcard/hoge' )->code, 200, '/wildcard/hoge';
    is $cb->( GET 'http://localhost/wildcard/fuga' )->code, 200, '/wildcard/fuga';
    is $cb->( GET 'http://localhost/wildcard/' )->code,     404, '/wildcard/';
  };

test_psgi
  app    => $app,
  client => sub {
    my $cb = shift;
    is $cb->( GET 'http://localhost/namedparam/faultier' )->content, 'faultier';
    is $cb->( GET 'http://localhost/namedparam/taro' )->content,     'taro';
  };

test_psgi
  app    => $app,
  client => sub {
    my $cb = shift;
    is $cb->( POST 'http://localhost/regex/1' )->code,  200, '/regex/1';
    is $cb->( POST 'http://localhost/regex/11' )->code, 404, '/regex/11';
    is $cb->( POST 'http://localhost/regex/' )->code,   404, '/regex/';
  };

done_testing;
