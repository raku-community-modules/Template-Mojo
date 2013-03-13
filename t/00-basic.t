use Test;
use Template::Mojo;

sub render($tmpl, *@a) {
    Template::Mojo.new($tmpl).render(|@a)
}

my @cases = (
    ['', ''],
    ['hello', 'hello'],
    ["empty\n\nline",                                             "empty\n\nline",           'empty line'],
    ["almost empty\n \nline",                                     "almost empty\n \nline",   'almost empty line'],
    ['hello <%%> world',                                          'hello  world'],
    ['hello <%= "world" %>',                                      'hello world'],
    [['answer = <%= $^a + $^b %>', 40, 2],                        'answer = 42'],
    ['hello <% "blarg" %> world',                                 'hello  world'],
    ["% for 1..3 \{\nhello\n% \}\n",                              "hello\nhello\nhello\n",   'for 1..3'],
    ["hello\n%# die 'this is an harmless comment'\nworld",        "hello\nworld",            '# comment in tag'],
    ["<a href='foo'>bar</a>",                                     "<a href='foo'>bar</a>"],
    [["a happy <%= \$^a %>\n", 'bar'],                            "a happy bar\n",           'a happy bar'],
    [["% my (\$a, \$b) = \@_\n<%= \$a %> and <%= \$b %>", 5, 7],  '5 and 7',                 'code'],
    ["% 0\n  an indented line\n%= 'foo'",                         "  an indented line\nfoo", 'indented line'],
);

plan 1 + 3 + @cases.elems;

for @cases -> $c {
    my ($tmpl, @params) = $c[0].WHAT === Str ?? ($c[0]) !! $c[0].list;

    is render($tmpl, @params), $c[1], ($c[2] // $c[0]);
}

my $err;
{
    $err = '';
    Template::Mojo.new('<%');
    CATCH {
        default { $err = $_ };
    }
}
ok $err ~~ /Failed\sto\sparse\sthe\stemplate/, 'Bad template exception';

{
    $err = '';
    Template::Mojo.new('<%= $^a + $^b %>').render(23);
    CATCH {
        default { $err = $_ };
    }
}
ok $err ~~ /Not\senough\spositional\sparameters\spassed\;\sgot\s1\sbut\sexpected\s2/, 'not enough arguments';

{
    $err = '';
    Template::Mojo.new('<%= $^a + $^b %>').render(23, 1, 4);
    CATCH {
        default { $err = $_ };
    }
}

ok $err ~~ /Too\smany\spositional\sparameters\spassed\;\sgot\s3\sbut\sexpected\s2/, 'too many arguments';

my $fh = open 'eg/template.tm', :r;
my $tmpl = $fh.slurp;
#diag $tmpl;
my $output = Template::Mojo.new($tmpl).render();
#diag $output;

# After changing the template one can save it with this code,
# examine it, and if found correct, keep it as the new expected data
#my $out = open 'eg/template.out', :w;
#$out.print($output);
#$out.close;

my $fh2 = open 'eg/template.out', :r;
my $expected = $fh2.slurp;
is $output, $expected, 'template.tm';



