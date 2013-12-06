use v6;
use Test;
use Template::Mojo;

plan 1;

my @cases = (
	{
		name => 'template',
	},
);

for @cases -> $c {
	my $fh = open "eg/$c<name>.tm", :r;
	my $tmpl = $fh.slurp;
	#diag $tmpl;
	my $output = Template::Mojo.new($tmpl).render();
	#diag $output;
	
	# After changing the template one can save it with this code,
	# examine it, and if found correct, keep it as the new expected data
	#my $out = open "eg/$c{name}.out", :w;
	#$out.print($output);
	#$out.close;
	
	my $fh2 = open "eg/$c<name>.out", :r;
	my $expected = $fh2.slurp;
	is $output, $expected, $c<name>;
}

