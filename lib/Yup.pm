use Yup::Runtime;
use Yup::Parser;
use Yup::Linter;

class Yup {
    method runtime(:$input = $*IN, :$output = $*OUT, :@arguments) {
        Yup::Runtime.new(:$input, :$output, :@arguments);
    }

    method parser(:$runtime = $.runtime) {
        Yup::Parser.new(:$runtime);
    }

    method !parser-with-no-output {
        my $output = my role NoOutput { method flush() {}; method print($) {} };
        my $runtime = self.runtime(:$output);
        self.parser(:$runtime);
    }

    method linter(:$parser = self!parser-with-no-output) {
        Yup::Linter.new(:$parser);
    }
}

# vim: ft=perl6
