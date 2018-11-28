use v6;
use Test;
use Yup::Test;

my @failing-typechecks;

my @files = find(".", /".pm" $/);
for @files -> $file {
    given slurp($file.IO) -> $content {
        for $content.comb(/"X::TypeCheck.new" <-[;]>+ ";"/) -> $typecheck {
            next unless $typecheck ~~ /":expected(" (<-[)]>+) ")"/;
            next unless $0 ~~ /^ '"'/;
            @failing-typechecks.push("\n(In $file):\n$typecheck");
        }
    }
}

is @failing-typechecks.join("\n"), "", "No X::TypeCheck :expected uses a literal string";

done-testing;
