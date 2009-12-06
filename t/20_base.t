use Test::More tests => 10;

BEGIN { use_ok 'Asagao::Base' }

{
    ok( Asagao::Base->can('psgi_app') );
    is ref( Asagao::Base->psgi_app ), 'CODE';
    ok( Asagao::Base->can('start_server') );
}

{

    package TestApp;
    use Asagao::Base;
    set views         => ['t/sample/views'];
    template gutentag => sub {
        'Guten Tag, <%= $name %>.';
    };
    __ASAGAO__;
}

{
    can_ok( TestApp, qw(get post put delete template) );
}

use HTTP::Request::Common;
use HTTP::Message::PSGI;
use Plack::Request;

sub create_testapp {
    my $env = GET('http://www.example.org/')->to_psgi;
    my $req = Plack::Request->new($env);
    TestApp->new( { req => $req } );
}

{
    my $app = create_testapp();
    can_ok( $app, qw(_run) );
}

{
    my $app = create_testapp();
    can_ok( $app, qw(mt) );
    is $app->mt( 'Hi, <%= $name %>.', { name => 'Taro' } ), 'Hi, Taro.';
    is $app->mt( ':hello',            { name => 'Taro' } ), "Hello, Taro.\n";
    is $app->mt( ':gutentag',         { name => 'Taro' } ), 'Guten Tag, Taro.';
}
