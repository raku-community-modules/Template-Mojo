use MONKEY-SEE-NO-EVAL;
grammar Template::Mojo::Grammar {
    token TOP {
        ^ <expression>* $
    }

    token expression {
        || <perlline>
        || <perlcapture-begin>
        || <perlcapture-end>
        || <perlcontent-for>
        || <perlcontent>
        || <perlextends>
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

    rule perlcontent-for {
        '<%' $<print>='='? 'content'$<form>=('-for'|'-with'|'') $<name>=\w+ '=>' 'begin' '%>'
    }

    rule perlcontent {
        '<%=' 'content' ('-'('for'|'with'))? ($<name>=\w+)? '%>'
    }

    rule perlextends {
        '<%' 'extends' $<template>=\w+ '%>'
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
        elsif $<perlcontent-for> {
            make $<perlcontent-for>.ast
        }
        elsif $<perlcontent> {
            make $<perlcontent>.ast
        }
        elsif $<perlextends> {
            make $<perlextends>.ast
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

    method perlcontent-for($/) {
        my $type  = $<form>.Str ?? $<form> !! '';
        my $print = $<print> eq '=' ?? True !! False;
        my $output = 'self.content' ~ $type ~ ': ' ~ $<name> ~ ' => sub {temp $_M = "";';

        if ($print) {
            return make '$_M ~= ' ~ $output;
        }

        return make $output;
    }

    method perlcontent($/) {
        if ($/[1]<name>) {
            return make '$_M ~= self.content: "' ~ $/[1]<name> ~ '";';
        }

        return make '$_M ~= self.content;';
    }

    method perlextends($/) {
        return make "self.extends: \"{ $<template> }\";";
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
    has %!content;
    has %!args;

    has Str $!extends; # parent template
    has Str $!layout;  # layout template

    has Str $!from; # directory of the templates

    submethod BUILD(:$code!, *%options) {
        &!code    = EVAL($code);
        $!from    = %options{'from'} // '';
        $!layout  = %options{'layout'} // '';
        %!content = %options{'content'} // ();

        return self;
    }

    method from-file(Str $filename is copy, *%options) {
        # option 'from' corresponds to the templates directory
        if (%options{'from'}) {
            $filename = %options{'from'} ~ '/' ~ $filename;
        }

        # if 'filename' extension isn't '.tm' add it
        if (!($filename ~~ m:i/\.tm$/)) {
            $filename ~= '.tm';
        }

        my $tmpl = $filename.IO.slurp;
        return self.new(
            $tmpl,
            name => $filename.IO.basename.split(".")[0],
            |%options,
        );
    }

    method new(Str $tmpl, :$name = "anon", *%options) {
        my $*TMPLNAME = $name;
        my $m = Template::Mojo::Grammar.parse(
            $tmpl, :actions(Template::Mojo::Actions.new)
        );
        unless $m {
            die X::Template::Mojo::ParseError.new(message => "Failed to parse the template")
        }

        self.bless: code => $m.ast, |%options;
    }

    method render(*@a, *%a) {
        %!args = (
            'list'  => @a,
            'named' => %a,
        );

        my Str $output = &!code.(|@a, |%a);

        return $output if !$!from;

        # process the parent template
        #   - read the template
        #   - process the template, need to pass:
        #       - %!content
        #       - %options
        if ($!extends) {
            my $extend_template = self.from-file(
                $!extends,
                from    => $!from,
                content => %!content,
            );

            $output ~= $extend_template.render(|@a, |%a,);
        }

        return $output if !$!layout;

        # process the layout template like the extended, but
        # return its output
        my $layout_template = self.from-file(
            $!layout ~ '.tm',
            from    => $!from,
            content => (
                |%!content,
                content => $output,
            ),
        );

        return $layout_template.render(|@a, |%a,);
    }

    method content-for(|args) {
        my $pair = args.pairs[0];
        return self._content(
            name   => $pair.key,
            block  => $pair.value,
            action => 'append',
        );
    }

    method content-with(|args) {
        my $pair = args.pairs[0];
        return self._content(
            name   => $pair.key,
            block  => $pair.value,
            action => 'replace',
        );
    }

    multi method content(Str $name) {
        return self._content(name => $name);
    }

    multi method content(|args) {
        if (!args.pairs.elems) {
            return self._content(name => 'content');
        }

        my $pair = args.pairs[0];
        return self._content(
            name   => $pair.key,
            block  => $pair.value,
        );
    }

    method extends(Str $template) {
        $!extends = $template;
    }

    method _content(Str :$name, :$block, *%options) {
        if (!$block.defined) {
            return %!content{$name} // '';
        }

        my $result = sub ($block) {
            my @expected_params = $block.signature.params;
            my %block_params    = ();
            for @expected_params -> $param {
                my Match $name = $param.name ~~ m/^\$(.*)$/;
                %block_params{$name[0]} = %!args{'named'}{$name[0]};
            }

            return $block.isa(Block) ?? $block.(|%block_params) !! $block;
        };

        given %options{'action'} {
            when 'append' {
                %!content{$name} ~= $result($block);
            }

            when 'replace' {
                %!content{$name} = $result($block);
            }

            default { # inheritance purpose
                %!content{$name} //= $result($block);
            }
        }

        return %!content{$name} // '';
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


