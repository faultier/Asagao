package Asagao::Role::Template;
use Any::Moose '::Role';

requires 'render_inline';
requires 'render_file';

1;
