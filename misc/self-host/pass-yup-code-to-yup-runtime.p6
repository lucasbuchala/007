use Yup;

sub run_007_on_007($program) {
    my $compunit = Yup.parser.parse($program);
    my $runtime-program = slurp("self-host/runtime.007");
    my $runtime = Yup.runtime;
    my $ast = Yup.parser(:$runtime).parse($runtime-program);
    $ast.block.static-lexpad.properties<ast> = $compunit;
    $runtime.run($ast);
}

multi MAIN($path) {
    run_007_on_007(slurp($path));
}

multi MAIN(Str :e($program)!) {
    run_007_on_007($program);
}
