use v6;
use Test;
use Template::Mojo;


my %params = (
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

plan 1;

#diag %params.perl;

my $tmpl = slurp "eg/complex.tm";
#diag $tmpl;
my $output = Template::Mojo.new($tmpl).render(%params);
#diag $output;
	
# After changing the template one can save it with this code,
# examine it, and if found correct, keep it as the new expected data
if 0 {
	my $out = open "eg/complex.out", :w;
	$out.print($output);
	$out.close;
}
	
my $expected = slurp "eg/complex.out";
is $output, $expected, 'complex';

