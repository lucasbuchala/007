use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        say(quasi { 1 + 1 });
        .

    my $expected = read(
        "(stmtlist (stexpr (infix:<+> (int 1) (int 1))))"
    ).block.Str;
    outputs $program, "$expected\n", "Basic quasi quoting";
}

{
    my $program = q:to/./;
        macro foo() {
            return quasi {
                say("OH HAI");
            }
        }

        foo();
        .

    outputs $program, "OH HAI\n", "Quasi quoting works for macro return value";
}

{
    my $program = q:to/./;
        constant greeting_ast = Q::Literal::Str { value: "Mr Bond!" };

        macro foo() {
            return quasi {
                say({{{greeting_ast}}});
            }
        }

        foo();
        .

    outputs $program, "Mr Bond!\n", "very basic unquote";
}

{
    my $program = q:to/./;
        macro foo() {
            my x = 7;
            return quasi {
                say(x);
            }
        }

        foo();
        .

    outputs $program, "7\n", "a variable is looked up in the quasi's environment";
}

{
    my $program = q:to/./;
        macro foo(expr) {
            my x = "oh noes";
            return quasi {
                say({{{expr}}});
            }
        }

        my x = "yay";
        foo(x);
        .

    outputs $program, "yay\n", "macro arguments also carry their original environment";
}

{
    my $program = q:to/./;
        macro moo() {
            sub infix:<**>(l, r) {
                return l ~ " to the " ~ r;
            }
            return quasi {
                say("pedal" ** "metal");
            }
        }

        moo();
        .

    outputs
        $program,
        "pedal to the metal\n",
        "operator used in quasi block carries its original environement";
}

done-testing;
