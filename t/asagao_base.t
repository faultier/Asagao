use Test::More tests => 13;

BEGIN { use_ok 'Asagao::Base' }

{
    ok( Asagao::Base->can('psgi_app') );
    is ref( Asagao::Base->psgi_app ), 'CODE';
    ok( Asagao::Base->can('start_server') );
}

{
    package TestApp;
    use Asagao::Base;
    __ASAGAO__;
}

{
    ok( TestApp->can('get') );
    ok( TestApp->can('post') );
    ok( TestApp->can('put') );
    ok( TestApp->can('delete') );
    ok( TestApp->can('get_dispatcher') );
    ok( TestApp->can('post_dispatcher') );
    ok( TestApp->can('put_dispatcher') );
    ok( TestApp->can('delete_dispatcher') );
}

{
    use HTTP::Request::Common;
    use HTTP::Message::PSGI;
    use Plack::Request;
    my $env = GET('http://www.example.org/')->to_psgi;
    my $req = Plack::Request->new($env);
    my $app = TestApp->new( { req => $req } );
    ok( $app->can('_run') );
}
