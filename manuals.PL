#!/usr/bin/env perl
#
# Generate tables in manual pages and for the lazy importer POSIX::3
# For unclear reason, it only works when both lib and blib versions of
# a pod get modified.

use warnings;
use strict;

use POSIX::1003::Confstr;
use POSIX::1003::Sysconf;
use POSIX::1003::Pathconf;
use POSIX::1003::Limit;
use POSIX::1003::Math;
use POSIX::1003::Signals;
use POSIX::1003::FdIO;
use POSIX::1003::FS;
use POSIX::1003::Termios;
use POSIX::1003::Events;

my @pods = map { ($_, "blib/$_") } @ARGV;

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

        print NEW "\n\n=for comment\n$old\n\n";
    }

    close NEW or die "write error in $podtmp: $!\n";
    close POD or die "read error in $pod: $!\n";

    if($changes) { rename $podtmp, $pod or die "rename $podtmp $pod: $!" }
    else         { unlink $podtmp       or die "unlink $podtmp: $!"  }
}

sub produce_table($)
{   my $table = shift;

    my @rows;

#warn "TABLE $table\n";
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
    elsif($table eq 'math')
    {   my $constants = $POSIX::1003::Math::EXPORT_TAGS{constants};
        no strict 'refs';
        foreach my $name (sort @$constants)
        {   my $val = &{"POSIX::1003::Math::$name"};
            defined $val or $val = 'undef';
            push @rows, [ $name, $val ];
        }
    }
    elsif($table eq 'math')
    {   my $constants = $POSIX::1003::Math::EXPORT_TAGS{constants};
        no strict 'refs';
        foreach my $name (sort @$constants)
        {   my $val = &{"POSIX::1003::Math::$name"};
            defined $val or $val = 'undef';
            push @rows, [ $name, $val ];
        }
    }
    elsif($table eq 'signals')
    {   my $constants = $POSIX::1003::Signals::EXPORT_TAGS{constants};
        no strict 'refs';
        foreach my $name (sort @$constants)
        {   my $val = &{"POSIX::1003::Signals::$name"};
            defined $val or $val = 'undef';
            push @rows, [ $name, $val ];
        }
    }
    elsif($table eq 'fdio')
    {   my $constants = $POSIX::1003::FdIO::EXPORT_TAGS{constants};
        no strict 'refs';
        foreach my $name (sort @$constants)
        {   my $val = &{"POSIX::1003::FdIO::$name"};
            defined $val or $val = 'undef';
            push @rows, [ $name, $val ];
        }
    }
    elsif($table eq 'fsys')
    {   my $constants = $POSIX::1003::FS::EXPORT_TAGS{constants};
        no strict 'refs';
        foreach my $name (sort @$constants)
        {   my $val = &{"POSIX::1003::FS::$name"};
            defined $val or $val = 'undef';
            push @rows, [ $name, $val ];
        }
    }
    elsif($table eq 'termios')
    {   my $constants = $POSIX::1003::Termios::EXPORT_TAGS{constants};
        no strict 'refs';
        foreach my $name (sort @$constants)
        {   my $val = &{"POSIX::1003::Termios::$name"};
            defined $val or $val = 'undef';
            push @rows, [ $name, $val ];
        }
    }
    elsif($table eq 'poll')
    {   my $poll = $POSIX::1003::Events::EXPORT_TAGS{poll};
        no strict 'refs';
        foreach my $name (sort @$poll)
        {   my $val = &{"POSIX::1003::Events::$name"};
            defined $val or $val = 'undef';
            push @rows, [ $name, $val ];
        }
    }
    else
    {   die "do not know how to make table $table";
    }

    my $longest_name = 0;
    my $longest_val  = 5;  # at least 'undef'
    for (@rows)
    {   $longest_name = length $_->[0] if $longest_name < length $_->[0];
        $longest_val  = length $_->[1] if $longest_val  < length $_->[1];
    }

    my @lines;
    foreach (@rows)
    {   my ($name, $value) = @$_;
        $name .= ' ' x ($longest_name - length $name);
        push @lines, "  $name   $value\n";
    }

    if($longest_name+$longest_val < 20)
    {    push @lines, "\n" while @lines %3;
         my $rows   = @lines / 3;
         my @left   = splice @lines, 0, $rows;
         chomp @left;
         my @middle = splice @lines, 0, $rows;
         chomp @middle;
         my @right = @lines;
         @lines = ();
         push @lines, sprintf "%-21s %-21s %s"
           , shift @left, shift @middle, shift @right
                 while @left;
    }
    elsif($longest_name+$longest_val < 30)
    {    push @lines, "\n" if @lines %2;
         my @left  = splice @lines, 0, @lines/2;
         chomp @left;
         my @right = @lines;
         @lines = ();
         push @lines, sprintf "%-31s  %s", shift @left, shift @right
             while @left;
    }
    @lines;
}
