use Yup::Val;
use Yup::Q;

# These multis are used below by infix:<==> and infix:<!=>
multi equal-value($, $) is export { False }
multi equal-value(Yup::Type::Nil, Yup::Type::Nil) { True }
multi equal-value(Yup::Type::Bool $l, Yup::Type::Bool $r) { $l.value == $r.value }
multi equal-value(Yup::Type::Int $l, Yup::Type::Int $r) { $l.value == $r.value }
multi equal-value(Yup::Type::Str $l, Yup::Type::Str $r) { $l.value eq $r.value }
multi equal-value(Yup::Type::Array $l, Yup::Type::Array $r) {
    if %*equality-seen{$l.WHICH} && %*equality-seen{$r.WHICH} {
        return $l === $r;
    }
    %*equality-seen{$l.WHICH}++;
    %*equality-seen{$r.WHICH}++;

    sub equal-at-index($i) {
        equal-value($l.elements[$i], $r.elements[$i]);
    }

    [&&] $l.elements == $r.elements,
        |(^$l.elements).map(&equal-at-index);
}
multi equal-value(Yup::Type::Object $l, Yup::Type::Object $r) {
    if %*equality-seen{$l.WHICH} && %*equality-seen{$r.WHICH} {
        return $l === $r;
    }
    %*equality-seen{$l.WHICH}++;
    %*equality-seen{$r.WHICH}++;

    sub equal-at-key(Str $key) {
        equal-value($l.properties{$key}, $r.properties{$key});
    }

    [&&] $l.properties.keys.sort.perl eq $r.properties.keys.sort.perl,
        |($l.properties.keys).map(&equal-at-key);
}
multi equal-value(Yup::Type::Type $l, Yup::Type::Type $r) {
    $l.type === $r.type
}
multi equal-value(Yup::Type::Sub $l, Yup::Type::Sub $r) {
    $l === $r
}
multi equal-value(Q $l, Q $r) {
    sub same-avalue($attr) {
        equal-value($attr.get_value($l), $attr.get_value($r));
    }

    [&&] $l.WHAT === $r.WHAT,
        |$l.attributes.map(&same-avalue);
}

# vim: ft=perl6
