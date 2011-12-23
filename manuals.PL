#!/usr/bin/env perl
#
# Generate tables in manual pages and for the lazy importer POSIX::3

use warnings;
use strict;

use POSIX::1003::Confstr;
use POSIX::1003::Sysconf;
use POSIX::1003::Pathconf;
use POSIX::1003::Limit;

my @pods = @ARGV;

sub produce_table($);

foreach my $pod (@pods)
{   $pod =~ m/\.pod$/
        or next;

    open POD, '<', $pod
        or die "cannot read $pod: $!\n";

    my $podtmp = "$pod.tmp";
    open NEW, '>', $podtmp
        or die "cannot write to $podtmp: $!\n";

    my $changes = 0;

    while(my $old = <POD>)
    {   print NEW $old;
        $old =~ m/^\#TABLE_(\w+)_START/
            or next;
        my $table = $1;

        do { $old = <POD> }
        until $old =~ m/^\#TABLE_${table}_END/;

        print NEW "\n";
        print NEW produce_table(lc $table);
        $changes++;

        print NEW <<_END;

=for comment
$old

_END
    }

    close NEW or die "write error in $podtmp: $!\n";
    close POD or die "read error in $pod: $!\n";

    if($changes) { rename $podtmp, $pod or die "rename $podtmp $pod: $!" }
    else         { unlink $podtmp       or die "unlink $podtmp: $!"  }
}

sub produce_table($)
{   my $table = shift;

    my @rows;

warn "TABLE $table\n";
    if($table eq 'confstr')
    {   my @names = confstr_names;
        foreach my $name (sort @names)
        {   my $val = confstr $name;
            push @rows, [ $name, defined $val ? "'$val'" : 'undef' ]
        }
    }
    elsif($table eq 'sysconf')
    {   my @names = sysconf_names;
        foreach my $name (sort @names)
        {   my $val = sysconf $name;
            push @rows, [ $name, defined $val ? $val : 'undef' ]
        }
    }
    elsif($table eq 'pathconf')
    {   my @names = pathconf_names;
        foreach my $name (sort @names)
        {   my $val = pathconf __FILE__, $name;
            push @rows, [ $name, defined $val ? $val : 'undef' ]
        }
    }
    elsif($table eq 'rlimit')
    {   my @names = rlimit_names;
        foreach my $name (sort @names)
        {   my ($soft, $hard, $success) = getrlimit $name;
            $soft //= 'undef';
            $hard //= 'undef';
            push @rows, [ $name, sprintf "%-25s %s", $soft, $hard ]
        }
    }
    elsif($table eq 'ulimit')
    {   my @names = ulimit_names;
        foreach my $name (sort @names)
        {   my $val = $name =~ m/GET/ ? ulimit $name : '(setter)';
            push @rows, [ $name, defined $val ? $val : 'undef' ]
        }
    }

else
{ return }

    my $longest_name = 0;
    ($longest_name < length $_->[0]) && ($longest_name = length $_->[0])
        for @rows;

    my @lines;
    foreach (@rows)
    {   my ($name, $value) = @$_;
        $name .= ' ' x ($longest_name - length $name);
        push @lines, "  $name   $value\n";
    }

    @lines;
}
