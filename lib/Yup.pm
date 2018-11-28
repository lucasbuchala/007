use Yu::Runtime;
use Yu::Parser;
use Yu::Linter;

class Yu {
    method runtime(:$input = $*IN, :$output = $*OUT, :@arguments) {
        Yu::Runtime.new(:$input, :$output, :@arguments);
    }

    method parser(:$runtime = $.runtime) {
        Yu::Parser.new(:$runtime);
    }

    method !parser-with-no-output {
        my $output = my role NoOutput { method flush() {}; method print($) {} };
        my $runtime = self.runtime(:$output);
        self.parser(:$runtime);
    }

    method linter(:$parser = self!parser-with-no-output) {
        Yu::Linter.new(:$parser);
    }
}

# vim: ft=perl6
