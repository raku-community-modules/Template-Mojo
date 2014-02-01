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

my $fh = open "eg/complex.tm", :r;
my $tmpl = $fh.slurp;
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
	
my $fh2 = open "eg/complex.out", :r;
my $expected = $fh2.slurp;
is $output, $expected, 'complex';

