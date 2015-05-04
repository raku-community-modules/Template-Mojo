grammar Template::Mojo::Grammar {
    token TOP {
        ^ <expression>* $
    }

    token expression {
        || <perlline>
        || <perlcapture-begin>
        || <perlcapture-end>
        || <perlexpr>
        || <characters>
    }

    token perlline {
        ^^ \h* '%' $<get-result>=['=']? $<expr>=[ <-[\n]>* ] [\n | $]
    }

    rule perlcapture-begin {
        '<%' 'my' $<name>=<var> '=' 'begin' '%>'
    }

    rule perlcapture-end {
        '<%' 'end' '%>'
    }

    token perlexpr {
        '<%' $<get-result>=['=']? $<expr>=[ [ <!before '%>' > . ]* ] '%>'
    }

    token var {
        <sigil> [ \w+ ]
    }

    token sigil {
        '&' | '$'
    }

    token characters {
        \n | [ <!before '<%' || \n > . ]+ \n?
    }
}

class Template::Mojo::Actions {
    method TOP($/) {
        my @exprs = $<expression>».ast;
        @exprs.unshift: 'my $_M = "";';
        @exprs.push: ';return $_M;';
        my $code = 'sub ' ~ $*TMPLNAME ~ ' { ' ~ @exprs.join ~ '}';
        make $code;
    }

    method expression($/) {
        if $<perlline> {
            make $<perlline>.ast
        }
        elsif $<perlcapture-begin> {
            make $<perlcapture-begin>.ast
        }
        elsif $<perlcapture-end> {
            make $<perlcapture-end>.ast
        }
        elsif $<perlexpr> {
            make $<perlexpr>.ast
        }
        else {
            make sprintf q[;$_M ~= '%s';],
                         $<characters>.Str.subst(/"'"/, "\\'", :g)
        }
    }

    method perlline($/) {
        make expr($/) ~ "\n"
    }

    method perlcapture-begin($/) {
        make 'my ' ~ $<name> ~ ' = sub {temp $_M = "";';
    }

    method perlcapture-end($/) {
        make ';return $_M};';
    }

    method perlexpr($/) {
        make expr($/)
    }

    sub expr($/) {
        if $<expr> ne '' {
            if $<get-result> ne '' {
                return ';$_M ~= ' ~ $<expr> ~ ';'
            }
            else {
                return $<expr>.Str
            }
        }
        else {
            return ''
        }
    }
}

class X::Template::Mojo::ParseError is Exception {
}

my $*TMPLNAME = "anon";

class Template::Mojo {
    has &.code;

    method from-file(Str $filename) {
        my $tmpl = $filename.IO.slurp;
        self.new($tmpl, name => $filename.IO.basename.split(".")[0]);
    }

    method new(Str $tmpl, :$name = "anon") {
        my $*TMPLNAME = $name;
        my $m = Template::Mojo::Grammar.parse(
            $tmpl, :actions(Template::Mojo::Actions.new)
        );
        unless $m {
            die X::Template::Mojo::ParseError.new(message => "Failed to parse the template")
        }
        self.bless: :code(EVAL $m.ast)
    }

    method render(*@a) {
        &.code.(|@a)
    }
}

=begin pod

=TITLE class Template::Mojo

A templating system modeled after the Perl 5 L<https://metacpan.org/module/Mojo::Template>

=head1 Synopsis

    my $tmpl = slurp 'eg/template.tm';

    my $t = Template::Mojo.new($tmpl);
    $t.render()

    my $ot = Template::Mojo.from-file('eg/template.tm');

=head1 Examples

=head2 Loop

=head3 Template

  % for 1..3 {
      hello
  % }

=head3 Code

  my $tmpl = slurp 'eg/template.tm';
  my $t = Template::Mojo.new($tmpl);
  $t.render()

=head3 Output

  hello
  hello
  hello

=head2 Parameters

=head3 Template

  % my ($x) = @_;

  <%= $x %>
  
  % for 1..$x {
      hello
  % }


See, on the first row of the template we accept a parameter as if this was a generic function call. Then we use the veriable in two different ways.

=head3 Code

The value to that subroutione can be passed in the render call:

  my $tmpl = slurp 'eg/template.tm';
  my $t = Template::Mojo.new($tmpl);
  $t.render(5)

=head3 Output:

  5
  
      hello
      hello
      hello
      hello
      hello

=head2 Passing hash

=head3 Template

  % my ($x) = @_;
  
  Fname: <%= $x<fname> %>
  Lname: <%= $x<lname> %>

=head3 Code

  my %params = (
    fname => 'Foo',
    lname => 'Bar',
  );

  my $tmpl = slurp 'eg/template.tm';
  my $t = Template::Mojo.new($tmpl);
  $t.render(%params)

=head3 Output

  Fname: Foo
  Lname: Bar

=head2 Complex examples

=head3 Template

  % my (%h) = @_;
  
  <h1><%= %h<title> %>
  
  <ul>
  % for %h<pages>.values -> $p {
    <li><a href="<%= $p<url> %>"><%= $p<title> %></a></li>
  % }
  </ul>

=head3 Code

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

  my $tmpl = slurp 'eg/template.tm';
  my $t = Template::Mojo.new($tmpl);
  $t.render(%params)

=head3 Output

  <h1>Perl 6 Links
  
  <ul>
    <li><a href="http://rakudo.org/">Rakudo</a></li>
    <li><a href="http://perl6.org/">Perl 6</a></li>
  </ul>

=head1 Copyright

Tadeusz Sośnierz

=end pod


