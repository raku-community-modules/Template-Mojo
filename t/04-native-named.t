use v6;
use Test;
use Template::Mojo;

plan 1;

my $tmpl = slurp "eg/native-named.tm";
# diag $tmpl;
my $output = Template::Mojo.new($tmpl).render(
   title => "Perl 6 Links",
   pages => [
      {
        "title" => "Rakudo",
        "url"   => "http://rakudo.org/",
      },
      {
        title   => 'Perl 6',
        url     => 'http://perl6.org/',
      }
   ],
);
#diag $output;
# After changing the template one can save it with this code,
# examine it, and if found correct, keep it as the new expected data
if 0 {
    my $out = open "eg/native-named.out", :w;
    $out.print($output);
    $out.close;
}

my $expected = slurp "eg/native-named.out";
is $output, $expected, 'complex';

