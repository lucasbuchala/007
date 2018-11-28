use v6;
use Test;
use Yup::Test;

{
    my $program = q:to/./;
        sub f() { say("OH HAI from inside sub") }
        .

    outputs $program, "", "subs are not immediate";
}

{
    my $program = q:to/./;
        my x = "one";
        say(x);
        sub f() {
            my x = "two";
            say(x);
        }
        f();
        say(x);
        .

    outputs $program, "one\ntwo\none\n", "subs have their own variable scope";
}

{
    my $program = q:to/./;
        sub f(name) {
            say("Good evening, Mr " ~ name);
        }
        f("Bond");
        .

    outputs $program, "Good evening, Mr Bond\n", "calling a sub with parameters works";
}

{
    my $program = q:to/./;
        sub f(x, y) {
            say(x ~ y);
        }
        my y = "y";
        f("X", y ~ y);
        .

    outputs $program, "Xyy\n", "arguments are evaluated before parameters are bound";
}

{
    my $program = q:to/./;
        sub f(callback) {
            my scoping = "dynamic";
            callback();
        }
        my scoping = "lexical";
        f(sub() { say(scoping) });
        .

    outputs $program, "lexical\n", "scoping is lexical";
}

{
    my $program = q:to/./;
        f();
        sub f() {
            say("OH HAI from inside sub");
        }
        .

    outputs $program, "OH HAI from inside sub\n", "call a sub before declaring it";
}

{
    my $program = q:to/./;
        f();
        my x = "X";
        sub f() {
            say(x);
        }
        .

    outputs $program, "nil\n", "using an outer lexical in a sub that's called before the outer lexical's declaration";
}

{
    my $program = q:to/./;
        sub f() { say("OH HAI") }
        sub g() { return f };
        g()();
        .

    outputs $program, "OH HAI\n",
        "left hand of a call doesn't have to be an identifier, just has to resolve to a callable";
}

{
    my $program = 'f("Bond"); sub f(name) { say("Good evening, Mr " ~ name) }';

    outputs $program, "Good evening, Mr Bond\n", "calling a post-declared sub works";
}

{
    my $program = 'my b = 42; sub g() { say(b) }; g()';

    outputs $program, "42\n", "lexical scope works correctly from inside a sub";
}

{
    my $program = q:to/./;
        sub f() {}
        f = 5;
        .

    parse-error
        $program,
        X::Assignment::RO,
        "cannot assign to a subroutine (#68)";
}

{
    my $program = q:to/./;
        sub f() {}
        sub h(a, b, f) {
            f = 17;
            say(f == 17);
        }
        h(0, 0, 7);
        say(f == 17);
        .

    outputs $program,
        "true\nfalse\n",
        "can assign to a parameter which hides a subroutine (#68)";
}

{
    my $program = q:to/./;
        my f = sub (x) { say(x) };
        f("Mr Bond");
        .

    outputs $program,
        "Mr Bond\n",
        "expression subs work";
}

{
    my $program = q:to/./;
        my f = sub g(x) { say(x) };
        f("Mr Bond");
        .

    outputs $program,
        "Mr Bond\n",
        "expression subs can be named, too";
}

{
    my $program = q:to/./;
        my f = sub g(x) {};
        say(f);
        .

    outputs $program,
        "<sub g(x)>\n",
        "...and they know their own name";
}

{
    my $program = q:to/./;
        my f = sub g() { say(g) };
        f();
        .

    outputs $program,
        "<sub g()>\n",
        "the name of a sub is visible inside the sub...";
}

{
    my $program = q:to/./;
        my f = sub g() {};
        g();
        .

    parse-error $program,
        X::Undeclared,
        "...but not outside of the sub";
}

{
    my $program = q:to/./;
        my f = sub () {
            my c = "Goldfinger";
            say(c);
        };

        f();
        .

    outputs $program,
        "Goldfinger\n",
        "can declare and use a variable in a term sub";
}

{
    my $program = q:to/./;
        sub f(x,) { }
        sub g(x,y,) { }
        .

    outputs $program, "", "trailing commas are allowed in parameterlist";
}

{
    my $program = q:to/./;
        sub f(x)   { say(1) }
        sub g(x,y) { say(2) }
        f(4,);
        g(4,5,);
        .

    outputs $program, "1\n2\n", "...and in argumentlist";
}

{
    my $program = 'sub subtract(x) { say(x) }; subtract("Mr Bond")';

    outputs $program, "Mr Bond\n", "it's OK to call your sub 'subtract'";
}

{
    my $program = q:to/./;
        sub fn()
        .

    my subset missing-block of X::Syntax::Missing where {
        is(.what, "block", "got the right missing thing");
        .what eq "block";
    };

    parse-error $program,
        missing-block,
        "parse error 'missing block' on missing block (#48)";
}

{
    my $program = q:to/./;
        sub b(count) {
            if count {
                b(count - 1);
                say(count);
            }
        }
        b(4);
        .

    outputs $program, "1\n2\n3\n4\n", "each sub invocation gets its own callframe/scope";
}

{
    my $program = q:to/./;
        say(sub () {});
        .

    outputs $program, "<sub ()>\n", "an anonymous sub stringifies without a name";
}

done-testing;
