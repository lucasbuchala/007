use Test;
use Yu::Test;

my @lines = run-and-collect-lines("ex/quicksort.yu");

is +@lines, 3, "correct number of lines of output";

{
    ok @lines[0] ~~ /^ "Unsorted: [" (\d+)+ % ", " "]" $/, "expected first line";
    my @values = @0».Int;
    ok sort(@values) eqv [^20].Seq, "got all the values in the expected range, in some order";
}

is @lines[1], "Sorting...";

{
    ok @lines[2] ~~ /^ "Sorted: [" (\d+)+ % ", " "]" $/, "expected first line";
    my @values = @0».Int;
    ok @values eqv [^20], "got all the values again, in sorted order";
}

done-testing;
