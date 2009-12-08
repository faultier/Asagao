use Test::More tests => 2;

BEGIN { use_ok 'Asagao::Config' }

my $config = Asagao::Config->instance;

{
    can_ok( $config, qw(template_include_path template_args) );
}
