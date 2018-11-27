use v6;
use Test;
use Yu;
use Yu::Linter;

{
    my $program = 'my x';
    my @complaints = Yu.linter.lint($program);
    ok @complaints ~~ [L::VariableNotUsed], "variable not used";
}

{
    my $program = 'my x = 7';
    my @complaints = Yu.linter.lint($program);
    ok @complaints ~~ [L::VariableNotUsed], "variable assigned but not used";
}

{
    my $program = 'my x = 7; say(x)';
    my @complaints = Yu.linter.lint($program);
    ok @complaints ~~ [], "variable is used; no complaint";
}

{
    my $program = 'my x = 7; say(x + x)';
    my @complaints = Yu.linter.lint($program);
    ok @complaints ~~ [], "variable is used in an expression; no complaint";
}

{
    my $program = '{ my x }; my x = 7; say(x)';
    my @complaints = Yu.linter.lint($program);
    ok @complaints ~~ [L::VariableNotUsed], "outer variable used, but not inner";
}

{
    my $program = '{ my x = 7; say(x) }; my x = 5';
    my @complaints = Yu.linter.lint($program);
    ok @complaints ~~ [L::VariableNotUsed], "inner variable used, but not outer";
}

{
    my $program = 'my x = 7; for [1, 2, 3] { say(x) }';
    my @complaints = Yu.linter.lint($program);
    ok @complaints ~~ [], "using a variable from a more nested scope than it was defined";
}

done-testing;
