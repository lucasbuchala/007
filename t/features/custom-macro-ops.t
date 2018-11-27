use v6;
use Test;
use Yu::Test;

{
    my $program = q:to/./;
        macro infix:<!!!>(l, r) {
        }
        .

    outputs
        $program,
         "",
        "defining macro op works";
}

{
    my $program = q:to/./;
        macro infix:<!!!>(l, r) {
            return new Q.Literal.Str { value: "OH HAI" };
        }

        say(1 !!! 2);
        .

    outputs
        $program,
        "OH HAI\n",
        "expanding a macro infix op and running the result at runtime";
}

{
    my $program = q:to/./;
        macro prefix:<@>(x) {
            return new Q.Literal.Str { value: "OH HAI" };
        }

        say(@7);
        .

    outputs
        $program,
        "OH HAI\n",
        "expanding a macro prefix op and running the result at runtime";
}

{
    my $program = q:to/./;
        macro postfix:<?!>(x) {
            return new Q.Literal.Str { value: "OH HAI" };
        }

        say([]?!);
        .

    outputs
        $program,
        "OH HAI\n",
        "expanding a macro postfix op and running the result at runtime";
}

done-testing;
