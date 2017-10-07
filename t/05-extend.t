use Test;
use Template::Mojo;

my $template = Template::Mojo.from-file('index.tm', from => 'eg/extend');
is($template.render(), 'eg/extend/index.out'.IO.slurp, 'extend');

done-testing;
