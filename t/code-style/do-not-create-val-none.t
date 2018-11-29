use v6;
use Test;
use Yup::Test;

my $files = find(".", /[".pm" | ".t"] $/)\
    .grep({ $_ !~~ / "do-not-create-val-none.t" / })\
    .join(" ");

my @lines-with-val-nil-new =
    qqx[grep -Fwrin 'Yup::Type::Nil.new' $files].lines\
        # exception: we store Yup::Type::Nil.new once as a constant
        .grep({ $_ !~~ /  ":constant NIL is export = " / });

is @lines-with-val-nil-new.join("\n"), "",
    "no unnecessary calls to Yup::Type::Nil.new";

done-testing;
