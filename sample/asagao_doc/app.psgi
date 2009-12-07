# vim: ft=perl enc=utf-8
use AsagaoDoc;

AsagaoDoc::set views  => [qw(views)];
AsagaoDoc::set static => 'public';

AsagaoDoc->psgi_app;
