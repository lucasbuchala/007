use v6;
use Test;
use Yu::Test;

my $files = find(".", /[".pm" | ".t"] $/)\
    .grep({ $_ !~~ / "do-not-create-val-none.t" / })\
    .join(" ");

my @lines-with-val-nil-new =
    qqx[grep -Fwrin 'Val::NilType.new' $files].lines\
        # exception: we store Val::NilType.new once as a constant
        .grep({ $_ !~~ /  ":constant NIL is export = " / });

is @lines-with-val-nil-new.join("\n"), "",
    "no unnecessary calls to Val::NilType.new";

done-testing;
