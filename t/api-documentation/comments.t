use v6;
use Test;

my %documented;

for «'doc/val.md' 'doc/q.md'» -> $file {
    for $file.IO.lines -> $line {
        my $prefix = $file eq 'doc/val.md' ?? 'Val::' !! '';  # XXX
        if $line ~~ /^ \h* '### ' (.+) / {  # a heading
            %documented{$prefix ~ $0} = True;
        }
    }
}

for <lib/Yup/Val.pm lib/Yup/Q.pm> -> $file {
    # I am a state machine. Hello.
    # my enum State <Normal ApiComment>;
    # my $state = Normal;

    for $file.IO.lines -> $line {
        if $line ~~ /^ < class role > \h+ (Q | < Val:: Q:: > \S+)/ {
            ok %documented{$0}, "$0 is documented";
            # ok $state == ApiComment, "$0 is documented";
        }

        # my &criterion = $state == Normal
        #     ?? /^ \h* '###' \h/
        #     !! /^ \h* '#'/;
        # $state = $line ~~ &criterion
        #     ?? ApiComment
        #     !! Normal;
    }
}

done-testing;
