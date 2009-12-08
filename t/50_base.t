use Test::More tests => 30;
use HTTP::Request::Common;
use HTTP::Message::PSGI;

BEGIN { use_ok 'Asagao::Base' }

{
    can_ok( Asagao::Base, 'psgi_app' );
    is ref( Asagao::Base->psgi_app ), 'CODE';
    can_ok( Asagao::Base, 'start_server' );
}

{

    package TestApp;
    use Asagao::Base;
    set views         => ['t/sample/views'];
    template gutentag => sub {
        'Guten Tag, <%= $name %>.';
    };
    get '/http_method'  => sub { 'GET Success' };
    post '/http_method' => sub { 'POST Success' };
    get '/wildcard/*'   => sub { 'Wildcard Success' };
    get '/namedparam/:hoge/:fuga' => sub {
        my $self = shift;
        sprintf( 'Named Parameter Success: hoge => %s, fuga => %s',
            $self->param('hoge'), $self->param('fuga') );
    };
    get qr{^/regexp/[0-9]$} => sub { 'Regexp Success' };
    __ASAGAO__;
}

{
    can_ok( TestApp, qw(get post template) );
}

my $app = TestApp->new();

{
    can_ok( $app, qw(run) );
}

{
    my $env;
    my $res;

    $env = GET('http://www.example.org/http_method')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 200;
    is $res->[2]->[0], 'GET Success';
    $env = POST( 'http://www.example.org/http_method', [] )->to_psgi;
    $res = $app->run($env);
    is $res->[0], 200;
    is $res->[2]->[0], 'POST Success';
    $env = HEAD('http://www.example.org/http_method')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 200;
    $env = HTTP::Request->new( OPTIONS => 'http://www.example.org/http_method' )->to_psgi;
    $res = $app->run($env);
    is $res->[0], 200;
    is $res->[1]->[1], 'GET, HEAD, POST, OPTIONS';
}

{
    my $env;
    my $res;
    $env = GET('http://www.example.org/wildcard/hoge')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 200;
    is $res->[2]->[0], 'Wildcard Success';
    $env = GET('http://www.example.org/wildcard/fuga')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 200;
    is $res->[2]->[0], 'Wildcard Success';
    $env = GET('http://www.example.org/wildcard/')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 404;
    $env = GET('http://www.example.org/wildcard')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 404;
}

{
    my $env;
    my $res;
    $env = GET('http://www.example.org/namedparam/hoge/fuga')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 200;
    is $res->[2]->[0], 'Named Parameter Success: hoge => hoge, fuga => fuga';
    $env = GET('http://www.example.org/namedparam/foo/bar')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 200;
    is $res->[2]->[0], 'Named Parameter Success: hoge => foo, fuga => bar';
    $env = GET('http://www.example.org/namedparam/hoge')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 404;
    $env = GET('http://www.example.org/namedparam/hoge/fuga/piyo')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 404;
}

{
    my $env;
    my $res;
    $env = GET('http://www.example.org/regexp/1')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 200;
    is $res->[2]->[0], 'Regexp Success';
    $env = GET('http://www.example.org/regexp/a')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 404;
    $env = GET('http://www.example.org/regexp/1/1')->to_psgi;
    $res = $app->run($env);
    is $res->[0], 404;
}

{
    can_ok( $app, qw(mt tt) );
}
