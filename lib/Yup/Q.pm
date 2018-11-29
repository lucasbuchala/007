use Yup::Val;

class X::Control::Return is Exception {
    has $.frame;
    has $.value;
}

class X::Subscript::TooLarge is Exception {
    has $.value;
    has $.length;

    method message() { "Subscript ($.value) too large (array length $.length)" }
}

class X::Subscript::NonInteger is Exception {
}

class X::Subscript::NonString is Exception {
}

class X::ParameterMismatch is Exception {
    has $.type;
    has $.paramcount;
    has $.argcount;

    method message {
        "$.type with $.paramcount parameters called with $.argcount arguments"
    }
}

class X::Property::NotFound is Exception {
    has $.propname;
    has $.type;

    method message {
        "Property '$.propname' not found on object of type $.type"
    }
}

class X::Associativity::Conflict is Exception {
    method message { "The operator already has a defined associativity" }
}

class X::Regex::InvalidMatchType is Exception {
    method message { "A regex can only match strings" }
}

class X::TypeCheck::HeterogeneousArray is Exception {
    has $.operation;
    has $.types;

    method message {
        "Can't do '$.operation' on heterogeneous array, types found: {$.types.sort}"
    }
}

class X::Yup::RuntimeException is Exception {
    has $.msg;

    method message {
        $.msg.Str;
    }
}

sub aname($attr) { $attr.name.substr(2) }
sub avalue($attr, $obj) { $attr.get_value($obj) }

role Q {
    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }

    method quoted-Str {
        self.Str
    }

    method truthy {
        True
    }

    method attributes {
        sub find($aname) { self.^attributes.first({ $aname eq aname($_) }) }

        self.can("attribute-order")
            ?? self.attribute-order.map({ find($_) })
            !! self.^attributes;
    }
}

role Q::Expr does Q {
    method eval($runtime) { ... }
}

role Q::Term does Q::Expr {
}

role Q::Literal does Q::Term {
}

class Q::Literal::Nil does Q::Literal {
    method eval($) { NIL }
}

class Q::Literal::Bool does Q::Literal {
    has Yup::Type::Bool $.value;

    method eval($) { $.value }
    method Str { $!value ?? 'true' !! 'false' }
}

class Q::Literal::Int does Q::Literal {
    has Yup::Type::Int $.value;

    method eval($) { $.value }
}

class Q::Literal::Str does Q::Literal {
    has Yup::Type::Str $.value;

    method eval($) { $.value }
}

class Q::Identifier does Q::Term {
    has Yup::Type::Str $.name;
    has $.frame = NIL;

    method attribute-order { <name> }

    method eval($runtime) {
        return $runtime.get-var($.name.value, $.frame);
    }

    method put-value($value, $runtime) {
        $runtime.put-var(self, $value);
    }
}

role Q::Regex::Fragment {
}

class Q::Regex::Str does Q::Regex::Fragment {
    has Yup::Type::Str $.contents;
}

class Q::Regex::Identifier does Q::Regex::Fragment {
    has Q::Identifier $.identifier;

    method eval($runtime) {
        # XXX check that the value is a string
        return $.identifier.eval($runtime);
    }
}

class Q::Regex::Call does Q::Regex::Fragment {
    has Q::Identifier $.identifier;
}

class Q::Regex::Alternation does Q::Regex::Fragment {
    has Q::Regex::Fragment @.alternatives;
}

class Q::Regex::Group does Q::Regex::Fragment {
    has Q::Regex::Fragment @.fragments;
}

class Q::Regex::OneOrMore does Q::Regex::Fragment {
    has Q::Regex::Fragment $.fragment;
}

class Q::Regex::ZeroOrMore does Q::Regex::Fragment {
    has Q::Regex::Fragment $.fragment;
}

class Q::Regex::ZeroOrOne does Q::Regex::Fragment {
    has Q::Regex::Fragment $.fragment;
}

class Q::Term::Regex does Q::Term {
    has Q::Regex::Fragment $.contents;

    method eval($runtime) {
        Yup::Type::Regex.new(:$.contents);
    }
}

class Q::Term::Array does Q::Term {
    has Yup::Type::Array $.elements;

    method eval($runtime) {
        Yup::Type::Array.new(:elements($.elements.elements.map(*.eval($runtime))));
    }
}

class Q::Term::Tuple does Q::Term {
    has Yup::Type::Tuple $.elements;

    method eval($runtime) {
        Yup::Type::Tuple.new(:elements($.elements.elements.map(*.eval($runtime))));
    }
}

class Q::Term::Object does Q::Term {
    has Yup::Type::Type $.type;
    has $.propertylist;

    method eval($runtime) {
        return $.type.create(
            $.propertylist.properties.elements.map({.key.value => .value.eval($runtime)})
        );
    }
}

class Q::Property does Q {
    has Yup::Type::Str $.key;
    has $.value;
}

class Q::PropertyList does Q {
    has Yup::Type::Array $.properties .= new;
}

role Q::Declaration {
    method is-assignable { False }
}

class Q::Trait does Q {
    has $.identifier;
    has $.expr;

    method attribute-order { <identifier expr> }
}

class Q::TraitList does Q {
    has Yup::Type::Array $.traits .= new;

    method attribute-order { <traits> }
}

class Q::Term::Sub does Q::Term does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has $.block;

    method attribute-order { <identifier traitlist block> }

    method eval($runtime) {
        my $name = $.identifier ~~ Yup::Type::Nil
            ?? Yup::Type::Str.new(:value(""))
            !! $.identifier.name;
        return Yup::Type::Sub.new(
            :$name,
            :parameterlist($.block.parameterlist),
            :statementlist($.block.statementlist),
            :static-lexpad($.block.static-lexpad),
            :outer-frame($runtime.current-frame),
        );
    }
}

class Q::Block does Q {
    has $.parameterlist;
    has $.statementlist;
    has Yup::Type::Object $.static-lexpad is rw = Yup::Type::Object.new;
    # XXX
    has $.frame is rw;

    method attribute-order { <parameterlist statementlist> }
}

class Q::Prefix does Q::Expr {
    has $.identifier;
    has $.operand;

    method attribute-order { <identifier operand> }

    method eval($runtime) {
        my $e = $.operand.eval($runtime);
        my $c = $.identifier.eval($runtime);
        return $runtime.call($c, [$e]);
    }
}

class Q::Infix does Q::Expr {
    has $.identifier;
    has $.lhs;
    has $.rhs;

    method attribute-order { <identifier lhs rhs> }

    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        my $r = $.rhs.eval($runtime);
        my $c = $.identifier.eval($runtime);
        return $runtime.call($c, [$l, $r]);
    }
}

class Q::Infix::Assignment is Q::Infix {
    method eval($runtime) {
        my $value = $.rhs.eval($runtime);
        $.lhs.put-value($value, $runtime);
        return $value;
    }
}

class Q::Infix::Or is Q::Infix {
    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        return $l.truthy
            ?? $l
            !! $.rhs.eval($runtime);
    }
}

class Q::Infix::DefinedOr is Q::Infix {
    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        return $l !~~ Yup::Type::Nil
            ?? $l
            !! $.rhs.eval($runtime);
    }
}

class Q::Infix::And is Q::Infix {
    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        return !$l.truthy
            ?? $l
            !! $.rhs.eval($runtime);
    }
}

class Q::Postfix does Q::Expr {
    has $.identifier;
    has $.operand;

    method attribute-order { <identifier operand> }

    method eval($runtime) {
        my $e = $.operand.eval($runtime);
        my $c = $.identifier.eval($runtime);
        return $runtime.call($c, [$e]);
    }
}

class Q::Postfix::Index is Q::Postfix {
    has $.index;

    method attribute-order { <identifier operand index> }

    method eval($runtime) {
        given $.operand.eval($runtime) {
            when Yup::Type::Array | Yup::Type::Tuple {
                my $index = $.index.eval($runtime);
                die X::Subscript::NonInteger.new
                    if $index !~~ Yup::Type::Int;
                die X::Subscript::TooLarge.new(:value($index.value), :length(+.elements))
                    if $index.value >= .elements;
                die X::Subscript::Negative.new(:$index, :type([]))
                    if $index.value < 0;
                return .elements[$index.value];
            }
            when Yup::Type::Object | Yup::Type::Sub | Q {
                my $property = $.index.eval($runtime);
                die X::Subscript::NonString.new
                    if $property !~~ Yup::Type::Str;
                my $propname = $property.value;
                return $runtime.property($_, $propname);
            }
            die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(Yup::Type::Array));
        }
    }

    method put-value($value, $runtime) {
        given $.operand.eval($runtime) {
            when Yup::Type::Array {
                my $index = $.index.eval($runtime);
                die X::Subscript::NonInteger.new
                    if $index !~~ Yup::Type::Int;
                die X::Subscript::TooLarge.new(:value($index.value), :length(+.elements))
                    if $index.value >= .elements;
                die X::Subscript::Negative.new(:$index, :type([]))
                    if $index.value < 0;
                .elements[$index.value] = $value;
            }
            when Yup::Type::Object | Q {
                my $property = $.index.eval($runtime);
                die X::Subscript::NonString.new
                    if $property !~~ Yup::Type::Str;
                my $propname = $property.value;
                $runtime.put-property($_, $propname, $value);
            }
            die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(Yup::Type::Array));
        }
    }
}

class Q::Postfix::Call is Q::Postfix {
    has $.argumentlist;

    method attribute-order { <identifier operand argumentlist> }

    method eval($runtime) {
        my $c = $.operand.eval($runtime);
        die "macro is called at runtime"
            if $c ~~ Yup::Type::Macro;
        die "Trying to invoke a {$c.^name.subst(/^'Yup::Type::'/, '')}" # XXX: make this into an X::
            unless $c ~~ Yup::Type::Sub;
        my @arguments = $.argumentlist.arguments.elements.map(*.eval($runtime));
        return $runtime.call($c, @arguments);
    }
}

class Q::Postfix::Property is Q::Postfix {
    has $.property;

    method attribute-order { <identifier operand property> }

    method eval($runtime) {
        my $obj = $.operand.eval($runtime);
        my $propname = $.property.name.value;
        $runtime.property($obj, $propname);
    }

    method put-value($value, $runtime) {
        given $.operand.eval($runtime) {
            when Yup::Type::Object | Q {
                my $propname = $.property.name.value;
                $runtime.put-property($_, $propname, $value);
            }
            die "We don't handle this case yet"; # XXX: think more about this case
        }
    }
}

class Q::Unquote does Q {
    has $.qtype;
    has $.expr;

    method eval($runtime) {
        die "Should never hit an unquote at runtime"; # XXX: turn into X::
    }
}

class Q::Unquote::Prefix is Q::Unquote {
    has $.operand;
}

class Q::Unquote::Infix is Q::Unquote {
    has $.lhs;
    has $.rhs;
}

class Q::Term::Quasi does Q::Term {
    has $.qtype;
    has $.contents;

    method attribute-order { <qtype contents> }

    method eval($runtime) {
        my $needs-displacement = $.contents !~~ Q::Block;

        sub interpolate($thing) {
            return $thing.new(:elements($thing.elements.map(&interpolate)))
                if $thing ~~ Yup::Type::Array;

            return $thing.new(:properties(%($thing.properties.map({ .key => interpolate(.value) }))))
                if $thing ~~ Yup::Type::Object;

            return $thing
                if $thing ~~ Yup::Value;

            return $thing.new(:name($thing.name), :frame($needs-displacement ?? $runtime.current-frame !! NIL))
                if $thing ~~ Q::Identifier;

            if $thing ~~ Q::Unquote::Prefix {
                my $prefix = $thing.expr.eval($runtime);
                die X::TypeCheck.new(:operation("interpolating an unquote"), :got($prefix), :expected(Q::Prefix))
                    unless $prefix ~~ Q::Prefix;
                return $prefix.new(:identifier($prefix.identifier), :operand($thing.operand));
            }
            elsif $thing ~~ Q::Unquote::Infix {
                my $infix = $thing.expr.eval($runtime);
                die X::TypeCheck.new(:operation("interpolating an unquote"), :got($infix), :expected(Q::Infix))
                    unless $infix ~~ Q::Infix;
                return $infix.new(:identifier($infix.identifier), :lhs($thing.lhs), :rhs($thing.rhs));
            }

            if $thing ~~ Q::Unquote {
                my $ast = $thing.expr.eval($runtime);
                die "Expression inside unquote did not evaluate to a Q" # XXX: turn into X::
                    unless $ast ~~ Q;
                return $ast;
            }

            my %attributes = $thing.attributes.map: -> $attr {
                aname($attr) => interpolate(avalue($attr, $thing))
            };

            $thing.new(|%attributes);
        }

        if $.qtype.value eq "Q.Unquote" && $.contents ~~ Q::Unquote {
            return $.contents;
        }
        my $r = interpolate($.contents);
        if $r ~~ Q::Block {
            $r.frame = $runtime.current-frame;
        }
        return $r;
    }
}

class Q::Parameter does Q does Q::Declaration {
    has $.identifier;

    method is-assignable { True }
}

class Q::ParameterList does Q {
    has Yup::Type::Array $.parameters .= new;
}

class Q::ArgumentList does Q {
    has Yup::Type::Array $.arguments .= new;
}

role Q::Statement does Q {
}

class Q::Term::My does Q::Term does Q::Declaration {
    has $.identifier;

    method is-assignable { True }

    method eval($runtime) {
        return $.identifier.eval($runtime);
    }

    method put-value($value, $runtime) {
        $.identifier.put-value($value, $runtime);
    }
}

class Q::Statement::Expr does Q::Statement {
    has $.expr;

    method run($runtime) {
        $.expr.eval($runtime);
    }
}

class Q::Statement::If does Q::Statement {
    has $.expr;
    has $.block;
    has $.else = NIL;

    method attribute-order { <expr block else> }

    method run($runtime) {
        my $expr = $.expr.eval($runtime);
        if $expr.truthy {
            my $paramcount = $.block.parameterlist.parameters.elements.elems;
            die X::ParameterMismatch.new(
                :type("If statement"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            $runtime.run-block($.block, [$expr]);
        }
        else {
            given $.else {
                when Q::Statement::If {
                    $.else.run($runtime)
                }
                when Q::Block {
                    my $paramcount = $.else.parameterlist.parameters.elements.elems;
                    die X::ParameterMismatch.new(
                        :type("Else block"), :$paramcount, :argcount("0 or 1"))
                        if $paramcount > 1;
                    $runtime.enter($runtime.current-frame, $.else.static-lexpad, $.else.statementlist);
                    for @($.else.parameterlist.parameters.elements) Z $expr -> ($param, $arg) {
                        $runtime.declare-var($param.identifier, $arg);
                    }
                    $.else.statementlist.run($runtime);
                    $runtime.leave;
                }
            }
        }
    }
}

class Q::Statement::Block does Q::Statement {
    has $.block;

    method run($runtime) {
        $runtime.enter($runtime.current-frame, $.block.static-lexpad, $.block.statementlist);
        $.block.statementlist.run($runtime);
        $runtime.leave;
    }
}

class Q::CompUnit is Q::Statement::Block {
}

class Q::Statement::For does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }

    method run($runtime) {
        my $count = $.block.parameterlist.parameters.elements.elems;
        die X::ParameterMismatch.new(
            :type("For loop"), :paramcount($count), :argcount("0 or 1"))
            if $count > 1;

        my $array = $.expr.eval($runtime);
        die X::TypeCheck.new(:operation("for loop"), :got($array), :expected(Yup::Type::Array))
            unless $array ~~ Yup::Type::Array;

        for $array.elements -> $arg {
            $runtime.run-block($.block, $count ?? [$arg] !! []);
        }
    }
}

class Q::Statement::While does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }

    method run($runtime) {
        while (my $expr = $.expr.eval($runtime)).truthy {
            my $paramcount = $.block.parameterlist.parameters.elements.elems;
            die X::ParameterMismatch.new(
                :type("While loop"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            $runtime.run-block($.block, $paramcount ?? [$expr] !! []);
        }
    }
}

class Q::Statement::Return does Q::Statement {
    has $.expr = NIL;

    method run($runtime) {
        my $value = $.expr ~~ Yup::Type::Nil ?? $.expr !! $.expr.eval($runtime);
        my $frame = $runtime.get-var("--RETURN-TO--");
        die X::Control::Return.new(:$value, :$frame);
    }
}

class Q::Statement::Throw does Q::Statement {
    has $.expr = NIL;

    method run($runtime) {
        my $value = $.expr ~~ Yup::Type::Nil
            ?? Yup::Type::Exception.new(:message(Yup::Type::Str.new(:value("Died"))))
            !! $.expr.eval($runtime);
        die X::TypeCheck.new(:got($value), :excpected(Yup::Type::Exception))
            if $value !~~ Yup::Type::Exception;

        die X::Yup::RuntimeException.new(:msg($value.message.value));
    }
}

class Q::Statement::Sub does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has Q::Block $.block;

    method attribute-order { <identifier traitlist block> }

    method run($runtime) {
    }
}

class Q::Statement::Macro does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has $.block;

    method attribute-order { <identifier traitlist block> }

    method run($runtime) {
    }
}

class Q::Statement::BEGIN does Q::Statement {
    has $.block;

    method run($runtime) {
        # a BEGIN block does not run at runtime
    }
}

class Q::Statement::Class does Q::Statement does Q::Declaration {
    has $.block;

    method run($runtime) {
        # a class block does not run at runtime
    }
}

class Q::StatementList does Q {
    has Yup::Type::Array $.statements .= new;

    method run($runtime) {
        for $.statements.elements -> $statement {
            my $value = $statement.run($runtime);
            LAST if $statement ~~ Q::Statement::Expr {
                return $value;
            }
        }
        return NIL;
    }
}

class Q::Expr::BlockAdapter does Q::Expr {
    has $.block;

    method eval($runtime) {
        $runtime.enter($.block.frame, $.block.static-lexpad, $.block.statementlist);
        my $result = $.block.statementlist.run($runtime);
        $runtime.leave;
        return $result;
    }
}

# vim: ft=perl6
