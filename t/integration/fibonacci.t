use v6;
use Test;
use Yup::Test;

{
    my $program = q:to/./;
        sub fib(n) {
            if n == 0 {
                return 1;
            }
            if n == 1 {
                return 1;
            }
            return fib(n - 1) + fib(n - 2);
        }

        say(fib(2));
        say(fib(3));
        say(fib(4));
        .

    outputs $program, "2\n3\n5\n", "recursive calls work out fine";
}

done-testing;
