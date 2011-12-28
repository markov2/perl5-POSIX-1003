#!/usr/bin/env perl
#
# This script builds .c files with constants, to be included in the XS

use Config;
use File::Spec;

use warnings;
use strict;

sub dump_table($$$);
sub from_listing($$);

my (%sc, %cs, %posix, %pc, %ul, %rl, %poll);

from_listing \%sc,    File::Spec->catfile('lists', 'sysconf.txt' );
from_listing \%cs,    File::Spec->catfile('lists', 'confstr.txt' );
from_listing \%pc,    File::Spec->catfile('lists', 'pathconf.txt');
from_listing \%posix, File::Spec->catfile('lists', 'posix.txt'   );
from_listing \%ul,    File::Spec->catfile('lists', 'ulimit.txt' );
from_listing \%rl,    File::Spec->catfile('lists', 'rlimit.txt' );
from_listing \%poll,  File::Spec->catfile('lists', 'poll.txt' );

#use Data::Dumper;
#warn Dumper \%sc, \%cs, \%posix, \%pc;

dump_table(\%sc,    'sc_table',   'sysconf.c'   );
dump_table(\%cs,    'cs_table',   'confstr.c'   );
dump_table(\%pc,    'pc_table',   'pathconf.c'  );
dump_table(\%posix, 'pr_table',   'properties.c');
dump_table(\%ul,    'ul_table',   'ulimit.c'    );
dump_table(\%rl,    'rl_table',   'rlimit.c'    );
dump_table(\%poll,  'poll_table', 'poll.c'    );

# System specific compilation helpers
open SYSTEM, '>', 'system.c'
    or die "cannot write to system.c: $!";

my $system = $^O;
my $incl   = File::Spec->catfile('system', "$system.c");
if(-f $incl)
{   print SYSTEM qq{#include "system/$system.c"\n};
}

close SYSTEM
    or die "write errors to system.c: $!";


exit 0;

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

sub from_listing($$)
{   my ($table, $filename) = @_;
    local *IN;
    open IN, '<', $filename
        or die "cannot read from $filename: $!";
    while(<IN>)
    {   next if m/^#|^\s*$/;
        chomp;
        $table->{$_}++;
    }
    close IN;
}
