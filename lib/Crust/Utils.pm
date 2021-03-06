use v6;

unit module Crust::Utils;

# internal use only. we'll change this file without notice.

sub parse-header-line(Str $header) is export {
    $header ~~ /^ (<-[: \s]>*) \s* \: \s* (.*) $/;
    return $/[0].Str.lc => $/[1].Str;
}

sub parse-header-item(Str $header) is export {
    my ($first, @items) = split(/\s*\;\s*/, $header);

    @items ==> map {
        $_ .= trim;
        my ($k, $v) = @(.split(/\=/));
        $v = $v.subst(/^\"(.*)\"$/, -> $/ { $/[0].Str });
        $k => $v
    } ==> my %opts;
    return $first.trim, %opts;
}

sub encode-html(Str $raw) is export {
    return $raw.trans(
        [ '&',     '<',    '>',    '"',      q{'}    ] =>
        [ '&amp;', '&lt;', '&gt;', '&quot;', '&#39;' ]
    );
}

sub status-with-no-entity-body(Int $status) returns Bool is export {
    return $status < 200 || $status == 204 || $status == 304;
}

sub content-length($body) is export {
    return Nil unless $body.defined;

    if $body.isa(List) {
        my $cl = 0;
        for @$body -> $chunk {
            my $length;
            given $chunk {
                when Str { $length = $chunk.encode.elems }
                when Blob { $length = $chunk.elems }
            }
            $cl += $length;
        }
        return $cl;
    } elsif $body.isa(IO::Handle) {
        return $body.s - $body.tell;
    }

    return Nil;
}

multi sub load-class($class) is export {
    require ::($class);
    return $class;
}

multi sub load-class($class is copy, $prefix) is export {
    unless $class ~~ s/^'+'// || $class ~~ /^$prefix/ {
        $class = $prefix ~ '::' ~ $class;
    }
    return load-class($class);
}

