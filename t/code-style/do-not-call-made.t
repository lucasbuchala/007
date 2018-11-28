use v6;
use Test;

my @lines-with-made =
    qqx[grep -Fwrin '.made' lib/Yup/Actions.pm].lines;  # XXX File may be non-existent

is @lines-with-made.join("\n"), "",
    "all .ast method calls are spelled '.ast' and not '.made'";

done-testing;
