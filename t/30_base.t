use Test::More tests => 10;

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
    __ASAGAO__;
}

{
    can_ok( TestApp, qw(get post put delete template) );
}

my $app = TestApp->new();

{
    can_ok( $app, qw(run) );
}

{
    can_ok( $app, qw(mt) );
    is $app->mt( 'Hi, <%= $name %>.', { name => 'Taro' } ), 'Hi, Taro.';
    is $app->mt( ':hello',            { name => 'Taro' } ), "Hello, Taro.\n";
    is $app->mt( ':gutentag',         { name => 'Taro' } ), 'Guten Tag, Taro.';
}
