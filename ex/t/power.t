use Test;
use Yup::Test;

my @lines = run-and-collect-lines("ex/power.yup");

is +@lines, 4, "correct number of lines of output";
is @lines[0], "8", "line #1 correct";
is @lines[1], "1", "line #2 correct";
is @lines[2], "42", "line #3 correct";
is @lines[3], "256", "line #4 correct";

done-testing;
