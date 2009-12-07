use Test::More tests => 5;

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
    can_ok( $ctx, qw(mt) );
    is $ctx->mt( 'Hi, <%= $name %>.', { name => 'Taro' } ), 'Hi, Taro.';
    is $ctx->mt( ':hello',            { name => 'Taro' } ), "Hello, Taro.\n";
    is $ctx->mt( ':gutentag',         { name => 'Taro' } ), 'Guten Tag, Taro.';
}
