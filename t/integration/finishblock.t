use v6;
use Test;

my $interested = False;
my Int $blocks-minus-finishblocks;
my Str $method;

for "lib/Yup/Actions.pm".IO.lines.kv -> $n, $line {
    if $interested && $line ~~ /^ "    " \} $/ {
        is $blocks-minus-finishblocks, 0, "method $method (line $n) has a self.finishblock for each Q::Block";
        $interested = False;
    }

    if $interested {
        if $line ~~ /"Q::Block.new("/ {
            $blocks-minus-finishblocks++;
        }
        if $line ~~ /"finish-block(" <-[)]>+ ");"/ {
            $blocks-minus-finishblocks--;
        }
    }

    if $line ~~ /^ "    method" \h* (<[\w\-\:]>+) / {
        $method = ~$0;
        $interested = True;
        $blocks-minus-finishblocks = 0;
    }
}

done-testing;
