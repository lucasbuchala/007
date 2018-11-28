use v6;
use Test;
use Yup::Test;

{
    my $program = q:to/./;
        say(1);
        .

    outputs $program, "1\n", "say() works";
}

{
    my $program = q:to/./;
        say(type(prompt(">>> ")));
        .

    outputs $program, ">>> \n<type Nil>\n", "say() works";
}

{
    my $program = q:to/./;
        say(type(nil));
        .

    outputs $program, "<type Nil>\n", "nil type() works";
}

{
    my $program = q:to/./;
        my n = 7;
        say(type(n));
        .

    outputs $program, "<type Int>\n", "Int type() works";
}

{
    my $program = q:to/./;
        my s = "Bond";
        say(type(s));
        .

    outputs $program, "<type Str>\n", "Str type() works";
}

{
    my $program = q:to/./;
        my a = [1, 2];
        say(type(a));
        .

    outputs $program, "<type Array>\n", "Array type() works";
}

{
    my $program = q:to/./;
        sub f() {}
        say(type(f));
        .

    outputs $program, "<type Sub>\n", "Sub type() works";
}

{
    my $program = q:to/./;
        say(type(say));
        .

    outputs $program, "<type Sub>\n", "builtin sub type() returns the same as ordinary func";
}

{
    my $program = q:to/./;
        say(0, 0, 7);
        say(say);
        .

    outputs $program, "007\n<sub say(...args)>\n", "builtin sub say() has varargs";
}

{
    my $program = q:to/./;
        exit();
        .

    has-exit-code $program, 0, "exit without a parameter";
}

{
    my $program = q:to/./;
        exit(1);
        .

    has-exit-code $program, 1, "exit with a parameter";
}

{
    my $program = q:to/./;
        exit(-1);
        .

    has-exit-code $program, 255, "exit is modulo 256";
}

{
    my $program = q:to/./;
        sub foo() {
            exit();
            say("foo");
        }

        sub bar() {
            foo();
            say("bar");
        }

        bar();
        .

    outputs $program, "", "nothing is run after exit()";
}

done-testing;
