use Test;
use _007;

my class StrOutput {
    has $.result = "";

    method flush() {}
    method print($s) { $!result ~= $s.gist }
}

sub run_007_on_007($program) {
    my $compunit = Yu.parser.parse($program);
    my $runtime-program = slurp("self-host/runtime.007");
    my $output = StrOutput.new;
    my $runtime = Yu.runtime(:$output);
    my $ast = Yu.parser(:$runtime).parse($runtime-program);
    $ast.block.static-lexpad.properties<ast> = $compunit;
    $runtime.run($ast);
    return $output.result;
}

is run_007_on_007(q[]), "", "empty program";
is run_007_on_007(q[say("Hello, James");]),
    "Hello, James\n",
    "simple print statement";

done-testing;
