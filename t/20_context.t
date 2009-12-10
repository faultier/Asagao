use Test::More tests => 7;

BEGIN { use_ok 'Asagao::Context' }

use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Plack::Request;

{
    package TestApp;
    use Asagao::Base;
    set views         => ['t/sample/views'];
    template gutentag => sub {
        'Guten Tag, <%= $name %>.';
    };
    __ASAGAO__;
}

my $app;

sub create_context {
    my $env = GET('http://www.example.org/')->to_psgi;
    my $req = Plack::Request->new($env);
    $app = TestApp->new( { req => $req } );
    Asagao::Context->new( { app => $app, req => $req });
}

{
    my $ctx = create_context();
    can_ok( $ctx, qw(param));
    can_ok( $ctx, qw(body status content_type redirect finalize));
}

{
    my $ctx = create_context();
    can_ok( $ctx, qw(render) );
    is $ctx->render( 'Hi, <%= $name %>.', { name => 'Taro' } ), 'Hi, Taro.';
    is $ctx->render( ':hello',            { name => 'Taro' } ), "Hello, Taro.\n";
    is $ctx->render( ':gutentag',         { name => 'Taro' } ), 'Guten Tag, Taro.';
}
