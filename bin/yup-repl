#! /bin/sh

rlwrap perl6 -e '
    use Yup;
    my $runtime = Yup.runtime;

    while defined my $program = prompt "> " {
        my $ast = Yup.parser(:$runtime).parse($program);
        $runtime.run($ast);
        CATCH {
            default {
                .say;
            }
        }
    }
'
