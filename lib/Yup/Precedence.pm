class Yup::Precedence {
    has Str $.assoc;
    has %.ops;

    method contains($op) {
        %.ops{$op}:exists;
    }

    method clone {
        self.new(:$.assoc, :%.ops);
    }
}

# vim: ft=perl6
