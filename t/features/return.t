use v6;
use Test;
use Yup::Test;

{
    my $program = q:to/./;
        sub f() {
            return 7;
        }

        say(f());
        .

    outputs $program, "7\n", "sub returning an Int";
}

{
    my $program = q:to/./;
        sub f() {
            return "Bond. James Bond.";
        }

        say(f());
        .

    outputs $program, "Bond. James Bond.\n", "sub returning a Str";
}

{
    my $program = q:to/./;
        sub f() {
            return [1, 2, "three"];
        }

        say(f());
        .

    outputs $program, qq<[1, 2, "three"]\n>, "sub returning a Str";
}

{
    my $program = q:to/./;
        sub f() {
            return 1953;
            say("Dead code. Should have returned by now");
        }

        say(f());
        .

    outputs $program, "1953\n", "a return statement forces immediate exit of the subroutine";
}

{
    my $program = q:to/./;
        sub f() {
            return;
        }

        say(f());
        .

    outputs $program, "nil\n", "sub returning nothing";
}

{
    my $program = q:to/./;
        sub f() {
            7;
        }

        say(f());
        .

    outputs $program, "7\n", "sub returning implicitly";
}

done-testing;
