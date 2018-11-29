use v6;
use Test;
use Yup::Test;

emits-p5 q:to '====', [], q:to '----', "empty program";
    ====
    ----

emits-p5 q:to '====', [], q:to '----', "hello world";
    say("Hello, world!");
    ====
    say("Hello, world!");
    ----

emits-p5 q:to '====', [], q:to '----', "'my' statement";
    my foo;
    my bar = 7;
    ====
    my $foo;
    my $bar = 7;
    ----

done-testing;
