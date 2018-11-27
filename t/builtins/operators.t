use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        say(38 + 4);
        .

    outputs $program, "42\n", "addition works";
}

{
    my $program = q:to/./;
        say(46 - 4);
        .

    outputs $program, "42\n", "subtraction works";
}

{
    my $program = q:to/./;
        say(6 * 7);
        .

    outputs $program, "42\n", "multiplication works";
}

{
    my $program = q:to/./;
        say(5 % 2);
        .

    outputs $program, "1\n", "modulo works";
}

{
    my $program = q:to/./;
        say(5 % -2);
        .

    outputs $program, "-1\n", "sign of modulo operation follows sign of divisor (rhs)";
}

{
    my $program = q:to/./;
        say(5 % 0);
        .

    runtime-error
        $program,
        X::Numeric::DivideByZero,
        "modulo by 0 is an error";
}

{
    my $program = q:to/./;
        say(5 %% 2);
        say(6 %% 2);
        say(5 %% -2);
        say(6 %% -2);
        .

    outputs $program, "false\ntrue\nfalse\ntrue\n", "divisibility operator works";
}

{
    my $program = q:to/./;
        say(5 %% 0);
        .

    runtime-error
        $program,
        X::Numeric::DivideByZero,
        "checking divisibility by 0 is an error";
}

{
    my $program = q:to/./;
        say("Jame" ~ "s Bond");
        .

    outputs $program, "James Bond\n", "string concatenation works";
}

{
    my $program = q:to/./;
        my ns = ["Jim", "Bond"];
        say(ns[1]);
        .

    outputs $program, "Bond\n", "array indexing works";
}

{
    my $program = q:to/./;
        my ns = [["Auric", "Goldfinger"]];
        say(ns[0][1]);
        .

    outputs $program, "Goldfinger\n", "array indexing works on something that is not a variable name";
}

{
    my $program = q:to/./;
        my x = 1;
        x = 2;
        say(x);
        .

    outputs $program, "2\n", "assignment works";
}

{
    my $program = q:to/./;
        my i1 = 10;
        my i2 = 11;
        say(i1 == i1);
        say(i1 == i2);
        .

    outputs $program, "true\nfalse\n", "integer equality";
}

{
    my $program = q:to/./;
        my i1 = 10;
        my i2 = 11;
        say(i1 != i1);
        say(i1 != i2);
        .

    outputs $program, "false\ntrue\n", "integer inequality";
}

{
    my $program = q:to/./;
        my s1 = "s1";
        my s2 = "s2";
        say(s1 == s1);
        say(s1 == s2);
        .

    outputs $program, "true\nfalse\n", "string equality";
}

{
    my $program = q:to/./;
        my s1 = "s1";
        my s2 = "s2";
        say(s1 != s1);
        say(s1 != s2);
        .

    outputs $program, "false\ntrue\n", "string inequality";
}

{
    my $program = q:to/./;
        my s1 = "a";
        my s2 = "b";
        say(s1 < s1);
        say(s1 < s2);
        .

    outputs $program, "false\ntrue\n", "string less-than";
}

{
    my $program = q:to/./;
        my s1 = "b";
        my s2 = "a";
        say(s1 > s1);
        say(s1 > s2);
        .

    outputs $program, "false\ntrue\n", "string greater-than";
}

{
    my $program = q:to/./;
        my a1 = [1, 2, 3];
        my a2 = [1, 2, "3"];
        say(a1 == a1);
        say(a1 == a2);
        .

    outputs $program, "true\nfalse\n", "array equality";
}
        
{
    my $program = q:to/./;
        my a1 = [1, 2, 3];
        my a2 = [1, 2, "3"];
        say(a1 != a1);
        say(a1 != a2);
        .

    outputs $program, "false\ntrue\n", "array inequality";
}

{
    my $program = q:to/./;
        my a3 = [1, 2, 3];
        a3[1] = a3;
        say(a3 == a3);
        .

    outputs $program, "true\n", "nested array equality";
}

{
    my $program = q:to/./;
        my o1 = { x: 7 };
        my o2 = { x: 9 };
        say(o1 == o1);
        say(o1 == o2);
        .

    outputs $program, "true\nfalse\n", "object equality";
}

{
    my $program = q:to/./;
        my o1 = { x: 7 };
        my o2 = { x: 9 };
        say(o1 != o1);
        say(o1 != o2);
        .

    outputs $program, "false\ntrue\n", "object inequality";
}

{
    my $program = q:to/./;
        my o3 = { x: 7 };
        o3.y = o3;
        say(o3 == o3);
        .

    outputs $program, "true\n", "nested object equality";
}

{
    my $program = q:to/./;
        say(Int == Int);
        say(Int == Str);
        .

    outputs $program, "true\nfalse\n", "type equality";
}

{
    my $program = q:to/./;
        say(Int != Int);
        say(Int != Str);
        .

    outputs $program, "false\ntrue\n", "type inequality";
}

{
    my $program = q:to/./;
        my i1 = 10;
        my s1 = "10";
        my a1 = [1, 2, 3];
        my o1 = { x: 7 };
        say(i1 == s1);
        say(s1 == a1);
        say(a1 == i1);
        say(o1 == i1);
        .

    outputs $program, "false\n" x 4, "equality testing across types (always false)";
}

{
    my $program = q:to/./;
        my i1 = 10;
        my s1 = "10";
        my a1 = [1, 2, 3];
        my o1 = { x: 7 };
        say(i1 != s1);
        say(s1 != a1);
        say(a1 != i1);
        say(o1 != i1);
        .

    outputs $program, "true\n" x 4, "inequality testing across types (always true)";
}

{
    outputs 'func foo() {}; say(foo == foo)', "true\n", "a func is equal to itself";
    outputs 'macro foo() {}; say(foo == foo)', "true\n", "a macro is equal to itself";
    outputs 'say(say == say)', "true\n", "a built-in func is equal to itself";
    outputs 'say(infix:<+> == infix:<+>)', "true\n", "a built-in operator is equal to itself";
    outputs 'say(new Q.Identifier { name: "foo" } == new Q.Identifier { name: "foo" })', "true\n",
        "two Qtrees with equal content are equal";
    outputs 'my a = []; for [1, 2] { func fn() {}; a = [fn, a] }; say(a[1][0] == a[0])',
        "false\n", "the same func from two different frames are different";
    outputs 'func foo() {}; my x = foo; { func foo() {}; say(x == foo) }', "false\n",
        "distinct funcs are unequal, even with the same name and bodies (I)";
    outputs 'func foo() { say("OH HAI") }; my x = foo; { func foo() { say("OH HAI") }; say(x == foo) }',
        "false\n", "distinct funcs are unequal, even with the same name and bodies (II)";

    outputs 'func foo() {}; func bar() {}; say(foo == bar)', "false\n",
        "distinct funcs are unequal";
    outputs 'macro foo() {}; macro bar() {}; say(foo == bar)', "false\n",
        "distinct macros are unequal";
    outputs 'say(say == type)', "false\n", "distinct built-in funcs are unequal";
    outputs 'say(infix:<+> == prefix:<->)', "false\n",
        "distinct built-in operators are unequal";
    outputs 'func foo(y) {}; my x = foo; { func foo(x) {}; say(x == foo) }', "false\n",
        "funcs with different parameters are unequal";
    outputs 'func foo() {}; my x = foo; { func foo() { say("OH HAI") }; say(x == foo) }', "false\n",
        "funcs with different bodies are unequal";
    outputs 'say(new Q.Identifier { name: "foo" } == new Q.Identifier { name: "bar" })', "false\n",
        "two Qtrees with distinct content are unequal";
}

{
    outputs 'say(1 < 2); say(2 > 1); say(1 <= 2); say(2 <= 0)', "true\ntrue\ntrue\nfalse\n",
        "relational operators work on integers";
    outputs 'say("a" < "b"); say("b" > "a"); say("a" <= "c"); say("a" <= "B")', "true\ntrue\ntrue\nfalse\n",
        "relational operators work on strings";
}

{
    outputs 'say(!false); say(!true); say(true || false); say(false || true); say(false && true)',
        "true\nfalse\ntrue\ntrue\nfalse\n",
        "boolean operators give the values expected";
    outputs 'say(false && say("foo")); say(true || say("bar"))', "false\ntrue\n",
        "boolean operators short-circuit";
    outputs 'say(1 && 2); say("" && 3); say(false || None); say([0, 0, 7] || false)', "2\n\nNone\n[0, 0, 7]\n",
        "boolean operators return one of their operands";
}

{
    my $program = q:to/./;
        say(None == None);
        say(None == 0);
        say(None == "");
        say(None == []);
        .

    outputs $program, "true\nfalse\nfalse\nfalse\n", "equality testing with None matches only itself";
}

{
    my $program = q:to/./;
        my ns = ["Jim", "Bond"];
        say(ns[-2]);
        .

    runtime-error
        $program,
        X::Subscript::Negative,
        "negative array indexing is an error";
}

{
    my $program = q:to/./;
        my ns = ["Jim", "Bond"];
        say(ns[19]);
        .

    runtime-error
        $program,
        X::Subscript::TooLarge,
        "indexing beyond the last element is an error";
}

{
    my $program = q:to/./;
        say(38 + "4");
        .

    runtime-error
        $program,
        X::TypeCheck,
        "adding non-ints is an error";
}

{
    my $program = q:to/./;
        say(38 ~ "4");
        .

    outputs $program, "384\n", "concatenating non-strs is OK (since #281)";
}

{
    my $program = q:to/./;
        my ns = "Jim";
        say(ns[0]);
        .

    runtime-error
        $program,
        X::TypeCheck,
        "indexing a non-array is an error";
}

{
    my $program = q:to/./;
        my a = [1, 2, 3];
        func f() { return 7 };
        my o = { foo: 12 };

        say(-a[1]);
        say(-f());
        say(-o.foo);

        say(!a[2]);
        say(!f());
        say(!o.foo);
        .

    outputs $program, "-2\n-7\n-12\nfalse\nfalse\nfalse\n", "all postfixes are tighter than both prefixes";
}

{
    my $program = q:to/./;
        say(1 + 2 * 3);
        say(2 * 3 + 4);

        say(1 - 2 * 3);
        say(2 * 3 - 4);
        .

    outputs $program, "7\n10\n-5\n2\n", "multiplication is tighter than addition/subtraction";
}

{
    my $program = q:to/./;
        say(1 == 2 != 3);
        .

    parse-error
        $program,
        X::Op::Nonassociative,
        "comparison operators are nonassociative";
}

{
    my $program = q:to/./;
        say(0 == 0 && "Bond");
        say(2 == 2 && 3 == 3);
        .

    outputs $program, "Bond\ntrue\n", "&& binds looser than ==";
}

{
    my $program = q:to/./;
        say(0 && 1 || "James");
        say(true || 0 && 0);
        .

    outputs $program, "James\ntrue\n", "&& binds tighter than ||";
}

{
    my $program = q:to/./;
        my x;

        x = 1 == 2;
        say(x);

        x = 0 || "foo";
        say(x);

        x = 1 && "bar";
        say(x);
        .

    outputs $program, "false\nfoo\nbar\n", "assignment binds looser than all the other operators";
}

{
    my $program = q:to/./;
        for ^3 -> n {
            say(n);
        }
        .

    outputs $program, "0\n1\n2\n", "upto operator works";
}

{
    my $program = q:to/./;
        for ^0 -> n {
            say(n);
        }
        for ^-3 -> n {
            say(n);
        }
        .

    outputs $program, "", "zero or negative numbers give an empty list for the upto operator";
}

{
    my $program = q:to/./;
        ^"Mr Bond"
        .

    runtime-error
        $program,
        X::TypeCheck,
        "can't upto a string (or other non-integer types)";
}

{
    my $program = q:to/./;
        my q = quasi<Q.Infix> { + }; say(q ~~ Q.Infix)
        .

    outputs $program, "true\n", "successful typecheck";
}

{
    my $program = q:to/./;
        my q = quasi<Q.Infix> { + }; say(q ~~ Q.Prefix)
        .

    outputs $program, "false\n", "unsuccessful typecheck";
}

{
    my $program = q:to/./;
        my q = 42; say(q ~~ Int)
        .

    outputs $program, "true\n", "typecheck works for Val::Int";
}

{
    my $program = q:to/./;
        my q = [4, 2]; say(q ~~ Array)
        .

    outputs $program, "true\n", "typecheck works for Val::Array";
}

{
    my $program = q:to/./;
        my q = {}; say(q ~~ Object)
        .

    outputs $program, "true\n", "typecheck works for Val::Object";
}

{
    my $program = q:to/./;
        say(quasi<Q.Infix> { + } !~~ Q.Infix);
        say(quasi<Q.Infix> { + } !~~ Q.Prefix);
        say(42 !~~ Int);
        say([4, 2] !~~ Array);
        say({} !~~ Object);
        say(42 !~~ Array);
        say([4, 2] !~~ Object);
        say({} !~~ Int);
        .

    outputs $program, "false\ntrue\nfalse\nfalse\nfalse\ntrue\ntrue\ntrue\n", "bunch of negative typechecks";
}

{
    my $program = q:to/./;
        say(42 // "oh, James");
        .

    outputs $program, "42\n", "defined-or with a defined lhs";
}

{
    my $program = q:to/./;
        say(None // "oh, James");
        .

    outputs $program, "oh, James\n", "defined-or with None as the lhs";
}

{
    my $program = q:to/./;
        say(0 // "oh, James");
        say("" // "oh, James");
        say([] // "oh, James");
        .

    outputs $program, "0\n\n[]\n", "0 and \"\" and [] are not truthy, but they *are* defined";
}

{
    my $program = q:to/./;
        func f() {
            say("I never get run, you know");
        }
        say(007 // f());
        .

    outputs $program, "7\n", "short-circuiting: if the lhs is defined, the (thunkish) rhs never runs";
}

{
    my $program = q:to/./;
        say("a" == "a" ~~ Bool);
        .

    parse-error $program,
        X::Op::Nonassociative,
        "infix:<~~> has the tightness of a comparison operator (and so is nonassociative)";
}

{
    my $program = q:to/./;
        say(-"42");
        .

    outputs $program, "-42\n", "the prefix negation operator also numifies strings";
}

{
    my $program = q:to/./;
        say(type(+"6"));
        say(type(+"-6"));
        .

    outputs $program, "<type Int>\n<type Int>\n", "prefix:<+> works";
}

{
    my $program = q:to/./;
        say(type(~6));
        .

    outputs $program, "<type Str>\n", "prefix:<~> works";
}

{
    my $program = q:to/./;
        say( +7 ~~ Int );
        .

    outputs
        $program,
        "true\n",
        "+Val::Int outputs a Val::Int (regression)";
}

{
    my $program = q:to/./;
        say( +"007" ~~ Int );
        .

    outputs
        $program,
        "true\n",
        "+Val::Str outputs a Val::Int (regression)";
}

{
    my $program = q:to/./;
        say( 5 divmod 2 );
        say( 5 divmod -2 );
        .

    outputs
        $program,
        "(2, 1)\n(-3, -1)\n",
        "divmod operator (happy path)";
}

{
    my $program = q:to/./;
        say( 5 divmod 0 );
        .

    runtime-error
        $program,
        X::Numeric::DivideByZero,
        "divmodding by 0 is an error";
}

done-testing;
