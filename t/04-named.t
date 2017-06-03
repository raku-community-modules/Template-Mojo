use v6;
use Test;
use Template::Mojo;

my %params;

plan 1;

my $tmpl = '%= %_<named>';
my $output = Template::Mojo.new($tmpl).render(named => 'awesome');

is $output, 'awesome', 'Can pass named arguments';
