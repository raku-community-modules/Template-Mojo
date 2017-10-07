use Test;
use Template::Mojo;

my $template = Template::Mojo.from-file(
    'index.tm',
    from   => 'eg/layout',
    layout => 'layout',
);
is($template.render(), 'eg/layout/index.out'.IO.slurp, 'layout');

done-testing;
