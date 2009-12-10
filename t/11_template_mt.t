use Test::More;
eval { require Text::MicroTemplate::Extended; };
plan skip_all => 'Text::MicroTemplate::Extended is not installed.' if $@;

plan tests => 4;

use Asagao::Config;
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
                tag_start => '<?',
                tag_end   => '?>',
            }
        }
    );
    is $mt->render_inline( 'Hi, <?= $name ?>.', { name => 'Taro' } ), 'Hi, Taro.';
    $mt = undef;
}

{
    Asagao::Config->instance->template_include_path( ['t/sample/views'] );
    $mt = Asagao::Template::MT->new;
    is $mt->render_file( 'hello', { name => 'Taro' } ), "Hello, Taro.\n";
    $mt = undef;
}
