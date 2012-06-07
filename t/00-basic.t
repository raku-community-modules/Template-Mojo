use Test;
use Template::Mojo;
plan 12;

sub render($tmpl, *@a) {
    Template::Mojo.new($tmpl).render(|@a)
}

is render(''), '';
is render('hello'), 'hello';
is render("empty\n\nline"), "empty\n\nline";
is render("almost empty\n \nline"), "almost empty\n \nline";
is render('hello <%%> world'), 'hello  world';
is render('hello <%= "world" %>'), 'hello world';
is render('answer = <%= $^a + $^b %>', 40, 2), 'answer = 42';
is render('hello <% "blarg" %> world'), 'hello  world';
is render("% for 1..3 \{\nhello\n% \}\n"), "hello\nhello\nhello\n";
is render("hello\n%# die 'this is an harmless comment'\nworld"), "hello\nworld";
is render("<a href='foo'>bar</a>"), "<a href='foo'>bar</a>";
is render("a happy <%= \$^a %>\n", 'bar'), "a happy bar\n";
