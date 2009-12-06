use Test::More;
eval { require Text::MicroTemplate::Extended; };
plan skip_all => 'Text::MicroTemplate::Extended is not installed.' if $@;

plan tests => 5;

use_ok 'Asagao::Template::MT';
my $mt;

{
    $mt = Asagao::Template::MT->new;
    is $mt->render_inline( 'Hi, <%= $name %>.', { name => 'Taro' } ), 'Hi, Taro.';
    $mt = undef;
}

{
    $mt = Asagao::Template::MT->new(
        {
            template_options => {
                tag_start  => '<?',
                tag_end    => '?>',
            }
        }
    );
    is $mt->render_inline( 'Hi, <?= $name ?>.', { name => 'Taro' } ), 'Hi, Taro.';
    $mt = undef;
}

{
    $mt = Asagao::Template::MT->new;
    $mt->set_infile_template( hi => 'Hi, <%= $name %>.' );
    is $mt->render( 'hi', { name => 'Taro' } ), 'Hi, Taro.';
    $mt = undef;
}

{
    $mt = Asagao::Template::MT->new( { include_path => ['t/sample/views'] } );
    is $mt->render('hello', { name => 'Taro' } ), "Hello, Taro.\n";
    $mt = undef;
}
