#!/usr/bin/env perl6
use v6;
use Yup;

multi MAIN($path, Bool :$lint!) {
    my $program = slurp($path);
    for Yup.linter.lint($program) -> $complaint {
        say "line N, column N: $complaint.message()";
    }
}

# vim: ft=perl6
