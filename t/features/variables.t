use v6;
use Test;
use Yu::Test;

{
    my $program = q:to/./;
        my u;
        say(u);
        .

    outputs $program, "nil\n", "variables can be declared without being assigned";
}

{
    my $program = q:to/./;
        my foo-bar-baz = 42;
        say(foo-bar-baz);
        .

    outputs $program, "42\n", "Identifiers can be hyphenated";
}

done-testing;
