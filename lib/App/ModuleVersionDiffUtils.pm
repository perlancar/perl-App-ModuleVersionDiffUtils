package App::ModuleVersionDiffUtils;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

our %SPEC;

sub _load_module {
    require Module::Path::More;

    my ($args, $which) = @_;

    my $paths;
    {
        local @INC = (@{ $args->{include_dir} // []}, @INC);

        $paths = Module::Path::More::module_path(
            module => $args->{module},
            all => 1,
        );
    }
    log_trace "Found module %s in %s", $args->{module}, $paths;

    if (@$paths < 2) {
        die "Found less than two versions of $args->{module}, need at least two";
    }

    (my $mod_pm = "$args->{module}.pm") =~ s!::!/!g;
    if ($which == 1) {
        do $paths->[0];
        $INC{$mod_pm} = $paths->[0];
    } else {
        do $paths->[1];
        $INC{$mod_pm} = $paths->[1];
    }
}

sub _load_first_module {
    my $args = shift;
    _load_module($args, 1);
}

# XXX how to turn off redefine warnings?
sub _load_second_module {
    my $args = shift;
    _load_module($args, 2);
}

our %args_module_spec = (
    include_dir => {
        schema => ['array*', of=>'dirname*'],
        cmdline_aliases => {I=>{}},
    },
    module => {
        schema => 'perl::modname*',
        description => <<'_',

Module will be searched in the `@INC` (you can specify `-I` to add more
directories to search). There needs to be at least two locations of the module.
Otherwise, the application will croak.

_
            req => 1,
            pos => 0,
        },
);

$SPEC{diff_two_module_version_hash} = {
    v => 1.1,
    args => {
        %args_module_spec,
        hash_name => {
            summary => 'Hash name to be found in module namespace, with sigil',
            schema => ['str*', match=>qr/\A[%$]\w+\z/],
        },
    },

    examples => [
        {
            argv => ['Foo::Bar', '%hash'],
            summary => 'Diff %hash between two versions of Foo::Bar',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => ['Foo::Bar', '$hashref'],
            summary => 'Diff $hashref between two versions of Foo::Bar',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub diff_two_module_version_hash {
    my %args = @_;

    my $mod = $args{module};
    _load_first_module(\%args);

    my $hash1;
    if ($args{hashname} =~ /\A%(.+)/) {
        $hash1 = { %{"$mod\::$1"} };
        %{"$mod\::$1"} = ();
    } elsif ($args{hashname} =~ /\A\$(.+)/) {
        $hash1 = ${"$mod\::$1"};
        die "\$$mod\::$1 is not a hashref" unless ref $hash1 eq 'HASH';
        $hash1 = {%$hash1};
        %{ ${"$mod\::$1"} } = ();
    } else {
        die "Invalid hashname $args{hashname}, must be '\%foo' or '\$foo'";
    }

    _load_second_module(\%args);

    my $hash2;
    if ($args{hashname} =~ /\A%(.+)/) {
        $hash2 = { %{"$mod\::$1"} };
        %{"$mod\::$1"} = ();
    } elsif ($args{hashname} =~ /\A\$(.+)/) {
        $hash2 = ${"$mod\::$1"};
        die "\$$mod\::$1 is not a hashref" unless ref $hash2 eq 'HASH';
        $hash2 = {%$hash2};
        %{ ${"$mod\::$1"} } = ();
    } else {
        die "Invalid hashname $args{hashname}, must be '\%foo' or '\$foo'";
    }

    use DD; dd {hash1=>$hash1, hash2=>$hash2};

    [200];
}

1;
#ABSTRACT: Utilities to diff stuffs from two different versions of a module

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

# INSERT_EXECS_LIST


=head1 SEE ALSO

=cut
