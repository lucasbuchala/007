#!/usr/bin/env perl6
use v6;
use Yup;
use Yup::Backend::Perl5;

class Ref {
    has Str $.deref;
}

sub ref($deref) {
    Ref.new(:$deref);
}

constant %BACKENDS = hash
    "default" => ref("runtime"),
    "runtime" => { $^runtime.run($^ast) },
    "perl5" => -> $ast, $ { print Yup::Backend::Perl5.new.emit($ast) },
    "p5" => ref("perl5"),
    "ast" => -> $ast, $ { say ~$ast },
    "unexpanded-ast" => -> $ast, $ { say ~$ast },
;

sub run_007($program, Str $backend is copy) {
    die "Unknown backend '$backend'"
        unless %BACKENDS{$backend} :exists;
    $backend = %BACKENDS{$backend}.deref
        while %BACKENDS{$backend} ~~ Ref;

    my $runtime = Yup.runtime;
    my $unexpanded = $backend eq "unexpanded-ast";
    my $ast = Yup.parser(:$runtime).parse($program, :$unexpanded);
    %BACKENDS{$backend}($ast, $runtime);
    exit($runtime.exit-code);
}

multi MAIN($path, Str :$backend = "default") {
    run_007(slurp($path), $backend);
}

multi MAIN(Str :e($program)!, Str :$backend = "default") {
    run_007($program, $backend);
}

# vim: ft=perl6
