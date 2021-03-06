use Yup::Val;
use Yup::Q;
use Yup::Builtins;
use Yup::Equal;

constant NO_OUTER = Yup::Type::Object.new;
constant RETURN_TO = Q::Identifier.new(
    :name(Yup::Type::Str.new(:value("--RETURN-TO--"))),
    :frame(NIL));
constant EXIT_SUCCESS = 0;

class Yup::Runtime {
    has $.input;
    has $.output;
    has @.arguments;
    has @!frames;
    has $.builtin-opscope;
    has $.builtin-frame;
    has $!p-builtin;
    has $!say-builtin;
    has $!prompt-builtin;
    has $!exit-builtin;
    has $.exit-code;

    submethod BUILD(:$!input, :$!output, :@!arguments) {
        $!builtin-opscope = opscope();
        $!builtin-frame = Yup::Type::Object.new(:properties(
            :outer-frame(NO_OUTER),
            :pad(builtins-pad()))
        );
        @!frames.push($!builtin-frame);
        $!p-builtin = builtins-pad().properties<p>;
        $!say-builtin = builtins-pad().properties<say>;
        $!prompt-builtin = builtins-pad().properties<prompt>;
        $!exit-builtin = builtins-pad().properties<exit>;
        $!exit-code = EXIT_SUCCESS;
    }

    method run(Q::CompUnit $compunit) {
        self.enter(self.current-frame, $compunit.block.static-lexpad, $compunit.block.statementlist);
        $compunit.block.statementlist.run(self);
        self.handle-main();
        self.leave();
        CATCH {
            when X::Control::Return {
                die X::ControlFlow::Return.new;
            }
            when X::Control::Exit {
                $!exit-code = .exit-code;
            }
        }
    }

    method handle-main() {
        if self.maybe-get-var("MAIN") -> $main {
            if $main ~~ Yup::Type::Sub {
                self.call($main, @!arguments.map(-> $value {
                    Yup::Type::Str.new(:$value)
                }));

                CATCH {
                    when X::ParameterMismatch {
                        my @main-parameters = $main.parameterlist.parameters.elements.map(*.identifier.name.value);
                        self.print-usage(@main-parameters);
                        $!exit-code = 1;
                    }
                }
            }
        }
    }

    method print-usage(@main-parameters) {
        $.output.print("Usage:");
        $.output.print("\n");
        $.output.print("  bin/007 <script> ");
        $.output.print(@main-parameters.map({ "<" ~ $_ ~ ">" }).join(" "));
        $.output.print("\n");
    }

    method enter($outer-frame, $static-lexpad, $statementlist, $routine?) {
        my $frame = Yup::Type::Object.new(:properties(:$outer-frame, :pad(Yup::Type::Object.new)));
        @!frames.push($frame);
        for $static-lexpad.properties.kv -> $name, $value {
            my $identifier = Q::Identifier.new(
                :name(Yup::Type::Str.new(:value($name))),
                :frame(NIL));
            self.declare-var($identifier, $value);
        }
        for $statementlist.statements.elements.kv -> $i, $_ {
            when Q::Statement::Sub {
                my $name = .identifier.name;
                my $parameterlist = .block.parameterlist;
                my $statementlist = .block.statementlist;
                my $static-lexpad = .block.static-lexpad;
                my $outer-frame = $frame;
                my $val = Yup::Type::Sub.new(
                    :$name,
                    :$parameterlist,
                    :$statementlist,
                    :$static-lexpad,
                    :$outer-frame
                );
                self.declare-var(.identifier, $val);
            }
        }
        if $routine {
            my $name = $routine.name;
            my $identifier = Q::Identifier.new(:$name, :$frame);
            self.declare-var($identifier, $routine);
        }
    }

    method leave {
        @!frames.pop;
    }

    method unroll-to($frame) {
        until self.current-frame === $frame {
            self.leave;
        }
    }

    method current-frame {
        @!frames[*-1];
    }

    method !find-pad(Str $symbol, $frame is copy) {
        self!maybe-find-pad($symbol, $frame)
            // die X::Undeclared.new(:$symbol);
    }

    method !maybe-find-pad(Str $symbol, $frame is copy) {
        if $frame ~~ Yup::Type::Nil {    # XXX: make a `defined` method on Nil so we can use `//`
            $frame = self.current-frame;
        }
        repeat until $frame === NO_OUTER {
            return $frame.properties<pad>
                if $frame.properties<pad>.properties{$symbol} :exists;
            $frame = $frame.properties<outer-frame>;
        }
        die X::ControlFlow::Return.new
            if $symbol eq RETURN_TO;
    }

    method put-var(Q::Identifier $identifier, $value) {
        my $name = $identifier.name.value;
        my $frame = $identifier.frame ~~ Yup::Type::Nil
            ?? self.current-frame
            !! $identifier.frame;
        my $pad = self!find-pad($name, $frame);
        $pad.properties{$name} = $value;
    }

    method get-var(Str $name, $frame = self.current-frame) {
        my $pad = self!find-pad($name, $frame);
        return $pad.properties{$name};
    }

    method maybe-get-var(Str $name, $frame = self.current-frame) {
        if self!maybe-find-pad($name, $frame) -> $pad {
            return $pad.properties{$name};
        }
    }

    method declare-var(Q::Identifier $identifier, $value?) {
        my $name = $identifier.name.value;
        my Yup::Type::Object $frame = $identifier.frame ~~ Yup::Type::Nil
            ?? self.current-frame
            !! $identifier.frame;
        $frame.properties<pad>.properties{$name} = $value // NIL;
    }

    method declared($name) {
        so self!maybe-find-pad($name, self.current-frame);
    }

    method declared-locally($name) {
        my $frame = self.current-frame;
        return True
            if $frame.properties<pad>.properties{$name} :exists;
    }

    method register-subhandler {
        self.declare-var(RETURN_TO, $.current-frame);
    }

    method run-block(Q::Block $block, @arguments) {
        self.enter(self.current-frame, $block.static-lexpad, $block.statementlist);
        for @($block.parameterlist.parameters.elements) Z @arguments -> ($param, $arg) {
            self.declare-var($param.identifier, $arg);
        }
        $block.statementlist.run(self);
        self.leave;
    }

    method call(Yup::Type::Sub $c, @arguments) {
        if $c === $!say-builtin {
            for @arguments -> $argument {
                $.output.print($argument.Str);
            }
            $.output.print("\n");
            return NIL;
        }
        elsif $c === $!p-builtin {
            for @arguments -> $argument {
                $.output.say($argument.quoted-Str);
            }
            return NIL;
        }
        else {
            my $paramcount = $c.parameterlist.parameters.elements.elems;
            my $argcount = @arguments.elems;
            die X::ParameterMismatch.new(:type<Sub>, :$paramcount, :$argcount)
                unless $paramcount == $argcount || $c === $!exit-builtin && $argcount < 2;
        }
        if $c === $!prompt-builtin {
            $.output.print(@arguments[0].Str);
            $.output.flush();
            my $value = $.input.get();
            if !$value.defined {
                $.output.print("\n");
                return NIL;
            }
            return Yup::Type::Str.new(:$value);
        }
        if $c.hook -> &hook {
            return &hook(|@arguments) || NIL;
        }
        self.enter($c.outer-frame, $c.static-lexpad, $c.statementlist, $c);
        for @($c.parameterlist.parameters.elements) Z @arguments -> ($param, $arg) {
            self.declare-var($param.identifier, $arg);
        }
        self.register-subhandler;
        my $frame = self.current-frame;
        my $value = $c.statementlist.run(self);
        self.leave;
        CATCH {
            when X::Control::Return {
                self.unroll-to($frame);
                self.leave;
                return .value;
            }
        }
        $value || NIL
    }

    method property($obj, Str $propname) {
        sub builtin(&fn) {
            my $name = &fn.name;
            my &ditch-sigil = { $^str.substr(1) };
            my &parameter = { Q::Parameter.new(:identifier(Q::Identifier.new(:name(Yup::Type::Str.new(:$^value))))) };
            my @elements = &fn.signature.params».name».&ditch-sigil».&parameter;
            my $parameterlist = Q::ParameterList.new(:parameters(Yup::Type::Array.new(:@elements)));
            my $statementlist = Q::StatementList.new();
            return Yup::Type::Sub.new-builtin(&fn, $name, $parameterlist, $statementlist);
        }

        my $type = Yup::Type::Type.of($obj.WHAT).name;
        if $obj ~~ Q {
            if $propname eq "detach" {
                sub aname($attr) { $attr.name.substr(2) }
                sub avalue($attr, $obj) { $attr.get_value($obj) }

                sub interpolate($thing) {
                    return $thing.new(:elements($thing.elements.map(&interpolate)))
                        if $thing ~~ Yup::Type::Array;

                    return $thing.new(:properties(%($thing.properties.map(.key => interpolate(.value)))))
                        if $thing ~~ Yup::Type::Object;

                    return $thing
                        if $thing ~~ Yup::Value;

                    return $thing.new(:name($thing.name), :frame(NIL))
                        if $thing ~~ Q::Identifier;

                    return $thing
                        if $thing ~~ Q::Unquote;

                    my %attributes = $thing.attributes.map: -> $attr {
                        aname($attr) => interpolate(avalue($attr, $thing))
                    };

                    $thing.new(|%attributes);
                }

                return builtin(sub detach() {
                    return interpolate($obj);
                });
            }

            sub aname($attr) { $attr.name.substr(2) }
            my %known-properties = $obj.WHAT.attributes.map({ aname($_) => 1 });
            # XXX: hack
            if $obj ~~ Q::Block {
                %known-properties<static-lexpad> = 1;
            }

            die X::Property::NotFound.new(:$propname, :$type)
                unless %known-properties{$propname};

            return $obj."$propname"();
        }
        elsif $obj ~~ Yup::Type::Int && $propname eq "abs" {
            return builtin(sub abs() {
                return Yup::Type::Int.new(:value($obj.value.abs));
            });
        }
        elsif $obj ~~ Yup::Type::Int && $propname eq "chr" {
            return builtin(sub chr() {
                return Yup::Type::Str.new(:value($obj.value.chr));
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "ord" {
            return builtin(sub ord() {
                return Yup::Type::Int.new(:value($obj.value.ord));
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "chars" {
            return builtin(sub chars() {
                return Yup::Type::Int.new(:value($obj.value.chars));
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "uc" {
            return builtin(sub uc() {
                return Yup::Type::Str.new(:value($obj.value.uc));
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "lc" {
            return builtin(sub lc() {
                return Yup::Type::Str.new(:value($obj.value.lc));
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "trim" {
            return builtin(sub trim() {
                return Yup::Type::Str.new(:value($obj.value.trim));
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "size" {
            return builtin(sub size() {
                return Yup::Type::Int.new(:value($obj.elements.elems));
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "index" {
            return builtin(sub index($value) {
                return Yup::Type::Int.new(:value(sub () {
                    for ^$obj.elements.elems -> $i {
                        my %*equality-seen;
                        if equal-value($obj.elements[$i], $value) {
                            return $i;
                        }
                    }
                    return -1;
                }()));
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "reverse" {
            return builtin(sub reverse() {
                return Yup::Type::Array.new(:elements($obj.elements.reverse));
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "sort" {
            return builtin(sub sort() {
                my $types = $obj.elements.map({ .^name }).unique;
                die X::TypeCheck::HeterogeneousArray.new(:operation<sort>, :$types)
                    if $types.elems > 1;
                return Yup::Type::Array.new(:elements($obj.elements.sort));
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "shuffle" {
            return builtin(sub shuffle() {
                return Yup::Type::Array.new(:elements($obj.elements.pick(*)));
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "concat" {
            return builtin(sub concat($array) {
                die X::TypeCheck.new(:operation<concat>, :got($array), :expected(Yup::Type::Array))
                    unless $array ~~ Yup::Type::Array;
                return Yup::Type::Array.new(:elements([|$obj.elements , |$array.elements]));
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "join" {
            return builtin(sub join($sep) {
                return Yup::Type::Str.new(:value($obj.elements.join($sep.value.Str)));
            });
        }
        elsif $obj ~~ Yup::Type::Object && $propname eq "size" {
            return builtin(sub size() {
                return Yup::Type::Int.new(:value($obj.properties.elems));
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "split" {
            return builtin(sub split($sep) {
                my @elements = (Yup::Type::Str.new(:value($_)) for $obj.value.split($sep.value));
                return Yup::Type::Array.new(:@elements);
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "index" {
            return builtin(sub index($substr) {
                return Yup::Type::Int.new(:value($obj.value.index($substr.value) // -1));
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "substr" {
            return builtin(sub substr($pos, $chars) {
                return Yup::Type::Str.new(:value($obj.value.substr(
                    $pos.value,
                    $chars.value)));
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "contains" {
            return builtin(sub contains($substr) {
                die X::TypeCheck.new(:operation<contains>, :got($substr), :expected(Yup::Type::Str))
                    unless $substr ~~ Yup::Type::Str;

                return Yup::Type::Bool.new(:value(
                        $obj.value.contains($substr.value)
                ));
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "prefix" {
            return builtin(sub prefix($pos) {
                return Yup::Type::Str.new(:value($obj.value.substr(
                    0,
                    $pos.value)));
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "suffix" {
            return builtin(sub suffix($pos) {
                return Yup::Type::Str.new(:value($obj.value.substr(
                    $pos.value)));
            });
        }
        elsif $obj ~~ Yup::Type::Str && $propname eq "charat" {
            return builtin(sub charat($pos) {
                my $s = $obj.value;

                die X::Subscript::TooLarge.new(:value($pos.value), :length($s.chars))
                    if $pos.value >= $s.chars;

                return Yup::Type::Str.new(:value($s.substr($pos.value, 1)));
            });
        }
        elsif $obj ~~ Yup::Type::Regex && $propname eq "fullmatch" {
            return builtin(sub fullmatch($str) {
                die X::Regex::InvalidMatchType.new
                    unless $str ~~ Yup::Type::Str;

                return Yup::Type::Bool.new(:value($obj.fullmatch($str.value)));
            });
        }
        elsif $obj ~~ Yup::Type::Regex && $propname eq "search" {
            return builtin(sub search($str) {
                die X::Regex::InvalidMatchType.new
                    unless $str ~~ Yup::Type::Str;

                return Yup::Type::Bool.new(:value($obj.search($str.value)));
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "grep" {
            return builtin(sub grep($fn) {
                my @elements = $obj.elements.grep({ self.call($fn, [$_]).truthy });
                return Yup::Type::Array.new(:@elements);
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "map" {
            return builtin(sub map($fn) {
                my @elements = $obj.elements.map({ self.call($fn, [$_]) });
                return Yup::Type::Array.new(:@elements);
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "push" {
            return builtin(sub push($newelem) {
                $obj.elements.push($newelem);
                return NIL;
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "pop" {
            return builtin(sub pop() {
                die X::Cannot::Empty.new(:action<pop>, :what($obj.^name))
                    if $obj.elements.elems == 0;
                return $obj.elements.pop();
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "shift" {
            return builtin(sub shift() {
                die X::Cannot::Empty.new(:action<pop>, :what($obj.^name))
                    if $obj.elements.elems == 0;
                return $obj.elements.shift();
            });
        }
        elsif $obj ~~ Yup::Type::Array && $propname eq "unshift" {
            return builtin(sub unshift($newelem) {
                $obj.elements.unshift($newelem);
                return NIL;
            });
        }
        elsif $obj ~~ Yup::Type::Type && $propname eq "name" {
            return Yup::Type::Str.new(:value($obj.name));
        }
        elsif $obj ~~ Yup::Type::Type && $propname eq "create" {
            return builtin(sub create($properties) {
                $obj.create($properties.elements.map({ .elements[0].value => .elements[1] }));
            });
        }
        elsif $obj ~~ Yup::Type::Sub && $propname eq any <outer-frame static-lexpad parameterlist statementlist> {
            return $obj."$propname"();
        }
        elsif $obj ~~ (Q | Yup::Type::Object) && ($obj.properties{$propname} :exists) {
            return $obj.properties{$propname};
        }
        elsif $propname eq "get" {
            return builtin(sub get($prop) {
                return self.property($obj, $prop.value);
            });
        }
        elsif $propname eq "keys" {
            return builtin(sub keys() {
                return Yup::Type::Array.new(:elements($obj.properties.keys.map({
                    Yup::Type::Str.new(:$^value)
                })));
            });
        }
        elsif $propname eq "has" {
            return builtin(sub has($prop) {
                # XXX: problem: we're not lying hard enough here. we're missing
                #      both Q objects, which are still hard-coded into the
                #      substrate, and the special-cased properties
                #      <get has extend update id>
                my $value = $obj.properties{$prop.value} :exists;
                return Yup::Type::Bool.new(:$value);
            });
        }
        elsif $propname eq "update" {
            return builtin(sub update($newprops) {
                for $obj.properties.keys {
                    $obj.properties{$_} = $newprops.properties{$_} // $obj.properties{$_};
                }
                return $obj;
            });
        }
        elsif $propname eq "extend" {
            return builtin(sub extend($newprops) {
                for $newprops.properties.keys {
                    $obj.properties{$_} = $newprops.properties{$_};
                }
                return $obj;
            });
        }
        elsif $propname eq "id" {
            # XXX: Make this work for Q-type objects, too.
            return Yup::Type::Int.new(:value($obj.id));
        }
        elsif $obj ~~ Yup::Type::Tuple && $propname eq "size" {
            return builtin(sub size() {
                return Yup::Type::Int.new(:value($obj.elements.elems));
            });
        }
        elsif $obj ~~ Yup::Type::Tuple && $propname eq "reverse" {
            return builtin(sub reverse() {
                return Yup::Type::Tuple.new(:elements($obj.elements.reverse));
            });
        }
        elsif $obj ~~ Yup::Type::Tuple && $propname eq "sort" {
            return builtin(sub sort() {
                my $types = $obj.elements.map({ .^name }).unique;
                die X::TypeCheck::HeterogeneousArray.new(:operation<sort>, :$types)
                    if $types.elems > 1;
                return Yup::Type::Tuple.new(:elements($obj.elements.sort));
            });
        }
        elsif $obj ~~ Yup::Type::Tuple && $propname eq "shuffle" {
            return builtin(sub shuffle() {
                return Yup::Type::Tuple.new(:elements($obj.elements.pick(*)));
            });
        }
        elsif $obj ~~ Yup::Type::Tuple && $propname eq "concat" {
            return builtin(sub concat($array) {
                die X::TypeCheck.new(:operation<concat>, :got($array), :expected(Yup::Type::Tuple))
                    unless $array ~~ Yup::Type::Tuple;
                return Yup::Type::Tuple.new(:elements([|$obj.elements , |$array.elements]));
            });
        }
        elsif $obj ~~ Yup::Type::Tuple && $propname eq "join" {
            return builtin(sub join($sep) {
                return Yup::Type::Str.new(:value($obj.elements.join($sep.value.Str)));
            });
        }
        elsif $obj ~~ Yup::Type::Tuple && $propname eq "grep" {
            return builtin(sub grep($fn) {
                my @elements = $obj.elements.grep({ self.call($fn, [$_]).truthy });
                return Yup::Type::Tuple.new(:@elements);
            });
        }
        elsif $obj ~~ Yup::Type::Tuple && $propname eq "map" {
            return builtin(sub map($fn) {
                my @elements = $obj.elements.map({ self.call($fn, [$_]) });
                return Yup::Type::Tuple.new(:@elements);
            });
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "ArgumentList" {
            return Yup::Type::Type.of(Q::ArgumentList);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "Block" {
            return Yup::Type::Type.of(Q::Block);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "CompUnit" {
            return Yup::Type::Type.of(Q::CompUnit);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "Identifier" {
            return Yup::Type::Type.of(Q::Identifier);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "Infix" {
            return Yup::Type::Type.of(Q::Infix);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "Literal" {
            return Yup::Type::Type.of(Q::Literal);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "ParameterList" {
            return Yup::Type::Type.of(Q::ParameterList);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "Postfix" {
            return Yup::Type::Type.of(Q::Postfix);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "Prefix" {
            return Yup::Type::Type.of(Q::Prefix);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "Statement" {
            return Yup::Type::Type.of(Q::Statement);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "StatementList" {
            return Yup::Type::Type.of(Q::StatementList);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q && $propname eq "Term" {
            return Yup::Type::Type.of(Q::Term);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q::Literal && $propname eq "Int" {
            return Yup::Type::Type.of(Q::Literal::Int);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q::Literal && $propname eq "Nil" {
            return Yup::Type::Type.of(Q::Literal::Nil);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q::Literal && $propname eq "Str" {
            return Yup::Type::Type.of(Q::Literal::Str);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q::Postfix && $propname eq "Call" {
            return Yup::Type::Type.of(Q::Postfix::Call);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q::Postfix && $propname eq "Property" {
            return Yup::Type::Type.of(Q::Postfix::Property);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q::Statement && $propname eq "Sub" {
            return Yup::Type::Type.of(Q::Statement::Sub);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q::Statement && $propname eq "If" {
            return Yup::Type::Type.of(Q::Statement::If);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q::Statement && $propname eq "Macro" {
            return Yup::Type::Type.of(Q::Statement::Macro);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q::Statement && $propname eq "My" {
            return Yup::Type::Type.of(Q::Statement::My);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q::Statement && $propname eq "Return" {
            return Yup::Type::Type.of(Q::Statement::Return);
        }
        elsif $obj ~~ Yup::Type::Type && $obj.type === Q::Term && $propname eq "Array" {
            return Yup::Type::Type.of(Q::Term::Array);
        }
        else {
            if $obj ~~ Yup::Type::Type {
                die X::Property::NotFound.new(:$propname, :type("$type ({$obj.type.^name})"));
            }
            die X::Property::NotFound.new(:$propname, :$type);
        }
    }

    method put-property($obj, Str $propname, $newvalue) {
        if $obj ~~ Q {
            die "We don't handle assigning to Q object properties yet";
        }
        elsif $obj !~~ Yup::Type::Object {
            die "We don't handle assigning to non-Yup::Type::Object types yet";
        }
        else {
            $obj.properties{$propname} = $newvalue;
        }
    }
}

# vim: ft=perl6
