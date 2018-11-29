use MONKEY-SEE-NO-EVAL;

class X::Uninstantiable is Exception {
    has Str $.name;

    method message() { "<type {$.name}> is abstract and uninstantiable"; }
}

class Helper { ... }

role Yup::Value {
    method truthy { True }
    method attributes { self.^attributes }
    method quoted-Str { self.Str }

    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }
}

class Yup::Type::Nil does Yup::Value {
    method truthy {
        False
    }
}

constant NIL is export = Yup::Type::Nil.new;

class Yup::Type::Bool does Yup::Value {
    has Bool $.value;

    method truthy {
        $.value;
    }

    method Str { $!value ?? 'true' !! 'false' }
}

class Yup::Type::Int does Yup::Value {
    has Int $.value;

    method truthy {
        ?$.value;
    }
}

class Yup::Type::Str does Yup::Value {
    has Str $.value;

    method quoted-Str {
        q["] ~ $.value.subst("\\", "\\\\", :g).subst(q["], q[\\"], :g) ~ q["]
    }

    method truthy {
        ?$.value;
    }
}

class Yup::Type::Regex does Yup::Value {
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

class Yup::Type::Array does Yup::Value {
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

class Yup::Type::Tuple does Yup::Value {
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

class Yup::Type::Object does Yup::Value {
    has %.properties{Str};
    has $.id = $global-object-id++;

    method quoted-Str {
        if %*stringification-seen{self.WHICH}++ {
            return "\{...\}";
        }
        return '{' ~ %.properties.map({
            my $key = .key ~~ /^<!before \d> [\w+]+ % '::'$/
                ?? .key
                !! Yup::Type::Str.new(value => .key).quoted-Str;
            "{$key}: {.value.quoted-Str}"
        }).sort.join(', ') ~ '}';
    }

    method truthy {
        ?%.properties
    }
}

class Yup::Type::Type does Yup::Value {
    has $.type;

    method of($type) {
        self.bless(:$type);
    }

    sub is-role($type) {
        my role R {};
        return $type.HOW ~~ R.HOW.WHAT;
    }

    method create(@properties) {
        if $.type ~~ Yup::Type::Object {
            return $.type.new(:@properties);
        }
        elsif $.type ~~ Yup::Type::Int | Yup::Type::Str {
            return $.type.new(:value(@properties[0].value.value));
        }
        elsif $.type ~~ Yup::Type::Array | Yup::Type::Tuple {
            return $.type.new(:elements(@properties[0].value.elements));
        }
        elsif $.type ~~ Yup::Type::Type {
            my $name = @properties[0].value;
            return $.type.new(:type(EVAL qq[class :: \{
                method attributes \{ () \}
                method ^name(\$) \{ "{$name}" \}
            \}]));
        }
        elsif $.type ~~ Yup::Type::Nil || $.type ~~ Yup::Type::Bool || is-role($.type) {
            die X::Uninstantiable.new(:$.name);
        }
        else {
            return $.type.new(|%(@properties));
        }
    }

    method name {
        $.type.^name.subst(/^ "Yup::Type::"/, "").subst(/"::"/, ".", :g);
    }
}

class Yup::Type::Sub does Yup::Value {
    has Yup::Type::Str $.name;
    has &.hook = Callable;
    has $.parameterlist;
    has $.statementlist;
    has Yup::Type::Object $.static-lexpad is rw = Yup::Type::Object.new;
    has Yup::Type::Object $.outer-frame;

    method new-builtin(&hook, Str $name, $parameterlist, $statementlist) {
        self.bless(:name(Yup::Type::Str.new(:value($name))), :&hook, :$parameterlist, :$statementlist);
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

    method Str { "<sub {$.escaped-name}{$.pretty-parameters}>" }
}

class Yup::Type::Macro is Yup::Type::Sub {
    method Str { "<macro {$.escaped-name}{$.pretty-parameters}>" }
}

class Yup::Type::Exception does Yup::Value {
    has Yup::Type::Str $.message;
}

class Helper {
    our sub Str($_) {
        when Yup::Type::Nil { 'nil' }
        when Yup::Type::Bool { .value.Str }
        when Yup::Type::Int { .value.Str }
        when Yup::Type::Str { .value }
        when Yup::Type::Regex { .quoted-Str }
        when Yup::Type::Array { .quoted-Str }
        when Yup::Type::Tuple { .quoted-Str }
        when Yup::Type::Object { .quoted-Str }
        when Yup::Type::Type { "<type {.name}>" }
        when Yup::Type::Macro { "<macro {.escaped-name}{.pretty-parameters}>" }
        when Yup::Type::Sub { "<sub {.escaped-name}{.pretty-parameters}>" }
        when Yup::Type::Exception { "Exception \{message: {.message.quoted-Str}\}" }
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
