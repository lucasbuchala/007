use MONKEY-SEE-NO-EVAL;

class X::Uninstantiable is Exception {
    has Str $.name;

    method message() { "<type {$.name}> is abstract and uninstantiable"; }
}

class Helper { ... }

role Val {
    method truthy { True }
    method attributes { self.^attributes }
    method quoted-Str { self.Str }

    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }
}

class Val::Nil does Val {
    method truthy {
        False
    }
}

constant NIL is export = Val::Nil.new;

class Val::Bool does Val {
    has Bool $.value;

    method truthy {
        $.value;
    }

    method Str { $!value ?? 'true' !! 'false' }
}

class Val::Int does Val {
    has Int $.value;

    method truthy {
        ?$.value;
    }
}

class Val::Str does Val {
    has Str $.value;

    method quoted-Str {
        q["] ~ $.value.subst("\\", "\\\\", :g).subst(q["], q[\\"], :g) ~ q["]
    }

    method truthy {
        ?$.value;
    }
}

class Val::Regex does Val {
    # note: a regex should probably keep its lexpad or something to resolve calls&identifiers
    has $.contents;

    method search(Str $str) {
        for ^$str.chars {
            return True with parse($str, $.contents, $_);
        }
        return False;
    }

    method fullmatch(Str $str) {
        return ?($_ == $str.chars with parse($str, $.contents, 0));
    }

    sub parse($str, $fragment, Int $last-index is copy) {
        when $fragment.^name eq "Q::Regex::Str" {
            my $value = $fragment.contents.value;
            my $slice = $str.substr($last-index, $value.chars);
            return Nil if $slice ne $value;
            return $last-index + $value.chars;
        }
        #when Q::Regex::Identifier {
        #    die "Unhandled regex fragment";
        #}
        #when Q::Regex::Call {
        #    die "Unhandled regex fragment";
        #}
        when $fragment.^name eq "Q::Regex::Group" {
            for $fragment.fragments -> $group-fragment {
                with parse($str, $group-fragment, $last-index) {
                    $last-index = $_;
                } else {
                    return Nil;
                }
            }
            return $last-index;
        }
        when $fragment.^name eq "Q::Regex::ZeroOrOne" {
            with parse($str, $fragment.fragment, $last-index) {
                return $_;
            } else {
                return $last-index;
            }
        }
        when $fragment.^name eq "Q::Regex::OneOrMore" {
            # XXX technically just a fragment+a ZeroOrMore
            return Nil unless $last-index = parse($str, $fragment.fragment, $last-index);
            loop {
                with parse($str, $fragment.fragment, $last-index) {
                    $last-index = $_;
                } else {
                    last;
                }
            }
            return $last-index;
        }
        when $fragment.^name eq "Q::Regex::ZeroOrMore" {
            loop {
                with parse($str, $fragment.fragment, $last-index) {
                    $last-index = $_;
                } else {
                    last;
                }
            }
            return $last-index;
        }
        when $fragment.^name eq "Q::Regex::Alternation" {
            for $fragment.alternatives -> $alternative {
                with parse($str, $alternative, $last-index) {
                    return $_;
                }
            }
            return Nil;
        }
        default {
            die "No handler for {$fragment.^name}";
        }
    }
}

class Val::Array does Val {
    has @.elements;

    method quoted-Str {
        if %*stringification-seen{self.WHICH}++ {
            return "[...]";
        }
        return "[" ~ @.elements>>.quoted-Str.join(', ') ~ "]";
    }

    method truthy {
        ?$.elements
    }
}

class Val::Tuple does Val {
    has @.elements;

    method quoted-Str {
        if %*stringification-seen{self.WHICH}++ {
            return "(...)";
        }
        return @.elements == 1
            ?? "(" ~ @.elements[0] ~ ",)"
            !! "(" ~ @.elements>>.quoted-Str.join(", ") ~ ")";
    }

    method truthy {
        ?$.elements;
    }
}

our $global-object-id = 0;

class Val::Object does Val {
    has %.properties{Str};
    has $.id = $global-object-id++;

    method quoted-Str {
        if %*stringification-seen{self.WHICH}++ {
            return "\{...\}";
        }
        return '{' ~ %.properties.map({
            my $key = .key ~~ /^<!before \d> [\w+]+ % '::'$/
                ?? .key
                !! Val::Str.new(value => .key).quoted-Str;
            "{$key}: {.value.quoted-Str}"
        }).sort.join(', ') ~ '}';
    }

    method truthy {
        ?%.properties
    }
}

class Val::Type does Val {
    has $.type;

    method of($type) {
        self.bless(:$type);
    }

    sub is-role($type) {
        my role R {};
        return $type.HOW ~~ R.HOW.WHAT;
    }

    method create(@properties) {
        if $.type ~~ Val::Object {
            return $.type.new(:@properties);
        }
        elsif $.type ~~ Val::Int | Val::Str {
            return $.type.new(:value(@properties[0].value.value));
        }
        elsif $.type ~~ Val::Array | Val::Tuple {
            return $.type.new(:elements(@properties[0].value.elements));
        }
        elsif $.type ~~ Val::Type {
            my $name = @properties[0].value;
            return $.type.new(:type(EVAL qq[class :: \{
                method attributes \{ () \}
                method ^name(\$) \{ "{$name}" \}
            \}]));
        }
        elsif $.type ~~ Val::Nil || $.type ~~ Val::Bool || is-role($.type) {
            die X::Uninstantiable.new(:$.name);
        }
        else {
            return $.type.new(|%(@properties));
        }
    }

    method name {
        $.type.^name.subst(/^ "Val::"/, "").subst(/"::"/, ".", :g);
    }
}

class Val::Func is Val {
    has Val::Str $.name;
    has &.hook = Callable;
    has $.parameterlist;
    has $.statementlist;
    has Val::Object $.static-lexpad is rw = Val::Object.new;
    has Val::Object $.outer-frame;

    method new-builtin(&hook, Str $name, $parameterlist, $statementlist) {
        self.bless(:name(Val::Str.new(:value($name))), :&hook, :$parameterlist, :$statementlist);
    }

    method escaped-name {
        sub escape-backslashes($s) { $s.subst(/\\/, "\\\\", :g) }
        sub escape-less-thans($s) { $s.subst(/"<"/, "\\<", :g) }

        return $.name.value
            unless $.name.value ~~ /^ (prefix | infix | postfix) ':' (.+) /;

        return "{$0}:<{escape-less-thans escape-backslashes $1}>"
            if $1.contains(">") && $1.contains("»");

        return "{$0}:«{escape-backslashes $1}»"
            if $1.contains(">");

        return "{$0}:<{escape-backslashes $1}>";
    }

    method pretty-parameters {
        sprintf "(%s)", $.parameterlist.parameters.elements».identifier».name.join(", ");
    }

    method Str { "<func {$.escaped-name}{$.pretty-parameters}>" }
}

class Val::Macro is Val::Func {
    method Str { "<macro {$.escaped-name}{$.pretty-parameters}>" }
}

class Val::Exception does Val {
    has Val::Str $.message;
}

class Helper {
    our sub Str($_) {
        when Val::Nil { 'nil' }
        when Val::Bool { .value.Str }
        when Val::Int { .value.Str }
        when Val::Str { .value }
        when Val::Regex { .quoted-Str }
        when Val::Array { .quoted-Str }
        when Val::Tuple { .quoted-Str }
        when Val::Object { .quoted-Str }
        when Val::Type { "<type {.name}>" }
        when Val::Macro { "<macro {.escaped-name}{.pretty-parameters}>" }
        when Val::Func { "<sub {.escaped-name}{.pretty-parameters}>" }
        when Val::Exception { "Exception \{message: {.message.quoted-Str}\}" }
        default {
            my $self = $_;
            my $name = .^name;
            die "Unexpected type -- some invariant must be broken"
                unless $name ~~ /^ "Q::"/;    # type not introduced yet; can't typecheck

            sub aname($attr) { $attr.name.substr(2) }
            sub avalue($attr, $obj) {
                my $value = $attr.get_value($obj);
                # XXX: this is a temporary fix until we patch Q::Unquote's qtype to be an identifier
                $value
                    ?? $value.quoted-Str
                    !! $value.^name.subst(/"::"/, ".", :g);
            }

            $name.=subst(/"::"/, ".", :g);

            my @attrs = $self.attributes;
            if @attrs == 1 {
                return "$name { avalue(@attrs[0], $self) }";
            }
            sub keyvalue($attr) { aname($attr) ~ ": " ~ avalue($attr, $self) }
            my $contents = @attrs.map(&keyvalue).join(",\n").indent(4);
            return "$name \{\n$contents\n\}";
        }
    }
}

# vim: ft=perl6
