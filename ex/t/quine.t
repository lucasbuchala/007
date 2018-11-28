use Test;
use Yu::Test;

my @lines = run-and-collect-lines("ex/quine.yu");

is @lines.map({ "$_\n" }).join,
    slurp("ex/quine.yu"),
    "the quine outputs itself";

done-testing;
