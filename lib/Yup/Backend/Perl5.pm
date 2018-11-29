use Yup::Val;
use Yup::Q;

my %builtins = (
    answer => 'sub answer { 42 }',
    what   => 'sub what { print my $s = "This is Yup\n"; $s }',
);

class Yup::Backend::Perl5 {
    method emit(Q::CompUnit $compunit) {
        return ""
            unless $compunit.block.statementlist.statements.elements;

        my @builtins;
        my @main;

        for $compunit.block.statementlist.statements.elements -> $stmt {
            emit-stmt($stmt);
        }

        my $builtins = @builtins.map({ "$_\n" }).join;
        my $main = @main.join("\n");
        return "#!/usr/bin/env perl\nuse v5.28;\n$builtins\n###CODE###\n$main\n__END__\n";

        multi emit-stmt(Q::Statement $stmt) {
            die "Cannot handle {$stmt.^name}";
        }

        multi emit-stmt(Q::Statement::Expr $stmt) {
            my $expr = $stmt.expr;
            when $expr ~~ Q::Postfix::Call
                && $expr.operand ~~ Q::Identifier
                && $expr.operand.name.value eq "say" {

                # @builtins.push(%builtins<say>);
                my @arguments = $expr.argumentlist.arguments.elements.map: {
                    die "Cannot handle non-literal-Str arguments just yet!"
                        unless $_ ~~ Q::Literal::Str;
                    .value.quoted-Str;
                };
                @main.push("say({@arguments.join(", ")});");
            }

            when $expr ~~ Q::Term::My {
                my $name = $expr.identifier.name.value;
                @main.push("my \${$name};");
            }

            when $expr ~~ Q::Infix::Assignment
                && $expr.lhs ~~ Q::Term::My {

                my $lhs = $expr.lhs;
                my $name = $lhs.identifier.name.value;
                my $rhs = $expr.rhs;

                die "Cannot handle non-literal-Int rhs just yet!"
                        unless $rhs ~~ Q::Literal::Int;
                my $int = $rhs.value.Str;
                @main.push("my \${$name} = {$int};");
            }

            die "Cannot handle this type of Q::Statement::Expr yet!";
        }
    }
}

# vim: ft=perl6
