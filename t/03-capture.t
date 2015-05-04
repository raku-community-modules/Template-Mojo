use v6;
use Test;
use Template::Mojo;

my %params;

plan 1;

my $tmpl = slurp "eg/capture.tm";
my $output = Template::Mojo.new($tmpl).render(%params);

diag $output;

my $expected = slurp "eg/capture.out";
is $output, $expected, 'capture';
