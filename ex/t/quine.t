use Test;
use Yup::Test;

my @lines = run-and-collect-lines("ex/quine.yup");

is @lines.map({ "$_\n" }).join,
    slurp("ex/quine.yup"),
    "the quine outputs itself";

done-testing;
