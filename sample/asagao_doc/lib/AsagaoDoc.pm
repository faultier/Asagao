package AsagaoDoc;

use Asagao::Base;

__PACKAGE__->config->{template}->{template_args}->{site_title} = 'Asagao'; 

get '/' => sub {
    my $self = shift;
    $self->mt(':index', { title => 'Asagao' });
};

__ASAGAO__
