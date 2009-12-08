use Test::More;

plan tests => 5;

use_ok 'Asagao::Template::TT';
my $tt;

{
    $tt = Asagao::Template::TT->new;
    is $tt->render_inline( 'Hi, <% name %>.', { name => 'Taro' } ), 'Hi, Taro.';
    $tt = undef;
}

{
    $tt = Asagao::Template::TT->new( { template_options => { TAG_STYLE => 'template', }, } );
    is $tt->render_inline( 'Hi, [% name %].', { name => 'Taro' } ), 'Hi, Taro.';
    $tt = undef;
}

{
    $tt = Asagao::Template::TT->new;
    $tt->set_infile_template( hi => 'Hi, <% name %>.' );
    is $tt->render( 'hi', { name => 'Taro' } ), 'Hi, Taro.';
    $tt = undef;
}

{
    $tt = Asagao::Template::TT->new( { include_path => ['t/sample/views'] } );
    is $tt->render( 'hello', { name => 'Taro' } ), "Hello, Taro.\n";
    $tt = undef;
}
