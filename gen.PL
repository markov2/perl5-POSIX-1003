#!/usr/bin/env perl
#
# This script builds .c files with constants, to be included in the XS

use Config;
use File::Spec;

use warnings;
use strict;

my $inc    = $Config{usrinc} || '/usr/include';
my $header = 'unistd.h';

sub unix_generic();
sub from_POSIX_pm();
sub scan_stream($);
sub dump_table($$$);

my (%sc, %cs, %posix, %pc);

my @try    =
  ( File::Spec->catfile($inc, $header)
  , File::Spec->catfile($inc, 'sys', $header)
  );

my $headerfn;
foreach my $filename (@try)
{   -f $filename or next;

    $headerfn = $filename;
    last;
}

eval {
    $headerfn
        or die "header <$header> not found\n";

    # platform dependent, needs more knowledge!
    unix_generic();
};

if($@)
{   my @lines = split /(?<=\n)/, $@;
    splice @lines, -4, 4 if @lines > 5;
    warn <<_WARN;
*** last lines of the failure:

@lines

*** unable to collect constants dynamically, so using
*** the knowledge of POSIX.pm.  Please contribute code
*** to improve the situation for your platform.

_WARN
    sleep 1;

    from_POSIX_pm();
}



#use Data::Dumper;
#warn Dumper \%sc, \%cs, \%posix, \%pc;

dump_table(\%sc,    'sc_table', 'sysconf.c');
dump_table(\%cs,    'cs_table', 'confstr.c');
dump_table(\%pc,    'pc_table', 'pathconf.c');
dump_table(\%posix, 'pr_table', 'properties.c');

exit 0;

sub unix_generic()
{   # This works for me on Linux: the _POSIX_ constants are
    # described in the comments so require '-C' to be detected.
    my @extra_flags = $^O eq 'linux' ? '-C' : ();

    my ($command, @flags) = split / /, $Config{cpprun};
    push @flags, @extra_flags, split(' ', $Config{cppflags});

    open PREP, "-|", $command, @flags, $headerfn
        or die "failed to collect expanded headers:\n$command @flags $headerfn\n";
    scan_stream \*PREP;
    close PREP;
}

sub from_POSIX_pm()
{   eval "require POSIX";
    warn "Extracting constants from POSIX\n";
    POSIX->import('O_CREAT');  # just pick one, otherwise we get all
    foreach my $export (@POSIX::EXPORT)
    {   next unless $export =~ m/^_(SC|CS|POSIX|PC)_/;
          $1 eq 'SC'    ? $sc{$export}++
        : $1 eq 'CS'    ? $cs{$export}++
        : $1 eq 'POSIX' ? $posix{$export}++
        :                 $pc{$export}++;
    }
}

sub scan_stream($)
{   my $in = shift;
    while(<$in>)
    {   $sc{$_}++    for m/\b(_SC_\w+)/g;
        $cs{$_}++    for m/\b(_CS_\w+)/g;
        $posix{$_}++ for m/\b(_POSIX_\w+)/g;
        $pc{$_}++    for m/\b(_PC_\w+)/g;
    }
}

sub dump_table($$$)
{   my ($consts, $table, $filename) = @_;
    local *TABLE;
    open TABLE, '>', $filename
        or die "cannot write to $filename: $!\n";

    print TABLE "/* Generated */\n\n";
    foreach my $const (sort keys %$consts)
    {   my $klen = length $const;
        print TABLE <<_CONST
#ifdef $const
(void)hv_store($table, "$const", $klen, newSViv($const), 0);
#endif
_CONST
    }

    close TABLE;
}
