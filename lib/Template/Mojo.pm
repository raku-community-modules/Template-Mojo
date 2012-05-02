grammar Template::Mojo::Grammar {
    token TOP {
        ^ <expression>* $
    }

    token expression {
        || <perlline>
        || <perlexpr>
        || <characters>
    }

    token perlline {
        ^^ \h* '%' $<get-result>=['=']? $<expr>=[ <-[\n]>* ] \s+
    }

    token perlexpr {
        '<%' $<get-result>=['=']? $<expr>=[ [ <!before '%>' > . ]* ] '%>'
    }

    token characters {
        [ <!before '<%' || \n > . ]+ \n?
    }
}

class Template::Mojo::Actions {
    method TOP($/) {
        my @exprs = $<expression>».ast;
        @exprs.unshift: 'my $_M = "";';
        @exprs.push: ';return $_M;';
        my $code = 'sub { ' ~ @exprs.join ~ '}';
        make $code;
    }

    method expression($/) {
        if $<perlline> {
            make $<perlline>.ast
        }
        elsif $<perlexpr> {
            make $<perlexpr>.ast
        }
        else {
            make sprintf q[;$_M ~= '%s';], $<characters>.Str;
        }
    }

    method perlline($/) {
        make expr($/) ~ "\n"
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

class Template::Mojo {
    has &.code;

    method new(Str $tmpl) {
        my $m = Template::Mojo::Grammar.parse(
            $tmpl, :actions(Template::Mojo::Actions.new)
        );
        unless $m {
            die "Failed to parse the template"
        }
        self.bless: *, :code(eval $m.ast)
    }

    method render(*@a) {
        &.code.(|@a)
    }
}

sub compile(Str $tmpl) {
    my $m = Template::Mojo::Grammar.parse(
        $tmpl, :actions(Template::Mojo::Actions.new)
    );
    if $m {
        say $m.ast;
        return eval $m.ast;
    }
}
