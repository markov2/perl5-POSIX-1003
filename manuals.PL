#!/usr/bin/env perl
#
# Generate tables in manual pages and for the lazy importer POSIX::3
# For unclear reason, it only works when both lib and blib versions of
# a pod get modified.

use warnings;
use strict;

my @pods   = map { ($_, "blib/$_") } @ARGV;

my %tables =
  ( confstr  => [ 'POSIX::1003::Confstr',  \&table_confstr  ]
  , sysconf  => [ 'POSIX::1003::Sysconf',  \&table_sysconf  ]
  , pathconf => [ 'POSIX::1003::Pathconf', \&table_pathconf ]
  , ulimit   => [ 'POSIX::1003::Limit',    \&table_ulimit   ]
  , rlimit   => [ 'POSIX::1003::Limit',    \&table_rlimit   ]
  , math     => [ 'POSIX::1003::Math',     \&table_math     ]
  , signals  => [ 'POSIX::1003::Signals',  \&table_signals  ]
  , fdio     => [ 'POSIX::1003::FdIO',     \&table_fdio     ]
  , fsys     => [ 'POSIX::1003::FS',       \&table_fsys     ]
  , termios  => [ 'POSIX::1003::Termios',  \&table_termios  ]
  , poll     => [ 'POSIX::1003::Events',   \&table_poll     ]
  , property => [ 'POSIX::1003::Properties', \&table_props  ]
  );

sub produce_table($$);
sub format_rows($$);

print "**** adding tables to manuals\n";

our $pod;   # sorry :(

foreach $pod (@pods)
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
        print NEW produce_table($pod, lc $table);
        $changes++;

        print NEW "\n\n=for comment\n$old\n\n";
    }

    close NEW or die "write error in $podtmp: $!\n";
    close POD or die "read error in $pod: $!\n";

    if($changes) { rename $podtmp, $pod or die "rename $podtmp $pod: $!" }
    else         { unlink $podtmp       or die "unlink $podtmp: $!"  }
}

sub produce_table($$)
{   my ($fn, $name) = @_;
    my $table = $tables{$name}
        or die "unknown table $name";

    my ($pkg, $handler) = @$table;
    eval "require $pkg";
    return "Compilation errors in module $pkg: $@" if $@;

    $pkg->import(':all');
    $handler->();
}

sub table_confstr()
{   my @names = confstr_names();

    my @rows;
    foreach my $name (sort @names)
    {   my $val = confstr($name);
        push @rows, [ $name, defined $val ? "'$val'" : 'undef' ]
    }
    format_rows confstr => \@rows;
}

sub table_sysconf()
{   my @names = sysconf_names();
    my @rows;
    foreach my $name (sort @names)
    {   my $val = sysconf($name);
        push @rows, [ $name, defined $val ? $val : 'undef' ]
    }
    format_rows sysconf => \@rows;
} 

sub table_pathconf()
{   my @names = pathconf_names();
    my @rows;
    foreach my $name (sort @names)
    {   my $val = pathconf(__FILE__, $name);
        push @rows, [ $name, defined $val ? $val : 'undef' ]
    }
    format_rows pathconf => \@rows;
}

sub table_rlimit()
{   my @names = rlimit_names();
    my @rows;
    foreach my $name (sort @names)
    {   my ($soft, $hard, $success) = getrlimit($name);
        $soft //= 'undef';
        $hard //= 'undef';
        push @rows, [ $name, sprintf "%-25s %s", $soft, $hard ]
    }
    format_rows rlimit => \@rows;
}

sub table_ulimit()
{   my @names = ulimit_names();
    my @rows;
    foreach my $name (sort @names)
    {   my $val = $name =~ m/GET/ ? ulimit($name) : '(setter)';
        push @rows, [ $name, defined $val ? $val : 'undef' ]
    }
    format_rows ulimit => \@rows;
}

sub table_math()
{   my $constants = $POSIX::1003::Math::EXPORT_TAGS{constants};
    my @rows;
    no strict 'refs';
    foreach my $name (sort @$constants)
    {   my $val = &{"POSIX::1003::Math::$name"};
        defined $val or $val = 'undef';
        push @rows, [ $name, $val ];
    }
    format_rows math => \@rows;
}

sub table_signals()
{   my $constants = $POSIX::1003::Signals::EXPORT_TAGS{constants};
    my @rows;
    no strict 'refs';
    foreach my $name (sort @$constants)
    {   my $val = &{"POSIX::1003::Signals::$name"};
        defined $val or $val = 'undef';
        push @rows, [ $name, $val ];
    }
    format_rows signals => \@rows;
}

sub table_fdio()
{   my $constants = $POSIX::1003::FdIO::EXPORT_TAGS{constants};
    my @rows;
    no strict 'refs';
    foreach my $name (sort @$constants)
    {   my $val = &{"POSIX::1003::FdIO::$name"};
        defined $val or $val = 'undef';
        push @rows, [ $name, $val ];
    }
    format_rows fdio => \@rows;
}

sub table_fsys()
{   my $constants = $POSIX::1003::FS::EXPORT_TAGS{constants};
    my @rows;
    no strict 'refs';
    foreach my $name (sort @$constants)
    {   my $val = &{"POSIX::1003::FS::$name"};
        defined $val or $val = 'undef';
        push @rows, [ $name, $val ];
    }
    format_rows fsys => \@rows;
}

sub table_termios()
{   my $constants = $POSIX::1003::Termios::EXPORT_TAGS{constants};
    my @rows;
    no strict 'refs';
    foreach my $name (sort @$constants)
    {   my $val = &{"POSIX::1003::Termios::$name"};
        defined $val or $val = 'undef';
        push @rows, [ $name, $val ];
    }
    format_rows termios => \@rows;
}

sub table_poll()
{   my $poll = $POSIX::1003::Events::EXPORT_TAGS{constants};
    my @rows;
    no strict 'refs';
    foreach my $name (grep /^POLL/, sort @$poll)
    {   my $val = &{"POSIX::1003::Events::$name"};
        defined $val or $val = 'undef';
        push @rows, [ $name, $val ];
    }
    format_rows poll => \@rows;
}

sub table_props()
{   my $poll = $POSIX::1003::Properties::EXPORT_TAGS{constants};
    my @rows;
    no strict 'refs';
    foreach my $name (sort @$poll)
    {   my $val = &{"POSIX::1003::Properties::$name"};
        defined $val or $val = 'undef';
        push @rows, [ $name, $val ];
    }
    format_rows property => \@rows;
}

sub format_rows($$)
{   my ($manual, $rows) = @_;

    my $longest_name = 0;
    my $longest_val  = 5;  # at least 'undef'

    my $nr_rows      = @$rows;
    my $nr_undef     = 0;

    for (@$rows)
    {   $longest_name = length $_->[0] if $longest_name < length $_->[0];
        $longest_val  = length $_->[1] if $longest_val  < length $_->[1];
    }

    my @lines;
    foreach (@$rows)
    {   my ($name, $value) = @$_;
        $name .= ' ' x ($longest_name - length $name);
        push @lines, "  $name   $value";
        $nr_undef++ if $value eq 'undef';
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
         my @right = @lines;
         @lines = ();
         push @lines, sprintf "%-31s  %s", shift @left, shift @right
             while @left;
    }

    warn sprintf "module %-8s has %3d constants, %2d are undefined\n",
        $manual, $nr_rows, $nr_undef
            if $pod !~ m/blib/;

    return join "\n", @lines, ''
        if @lines;

    <<_NONE;
There were no symbols detected for this category during installation.
This can mean that the related command is not supported, or that this
module did not get ported to (your version of) your Operating System.
In the latter case, please help us making it work.
_NONE
}

