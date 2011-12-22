#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 12;

use POSIX::1003::Limit qw(ulimit %ulimit UL_GETFSIZE);

my $fsize = ulimit('UL_GETFSIZE');
ok(defined $fsize, "UL_GETFSIZE via function = $fsize");

my $fsize2 = UL_GETFSIZE;
ok(defined $fsize2, "UL_GETFSIZE directly = $fsize2");
cmp_ok($fsize, 'eq', $fsize2);

my $key = $ulimit{UL_GETFSIZE};
ok(defined $key, "key UL_GETFSIZE = $key");

my $fsize3;
eval { $fsize3 = ulimit($key) };
like($@, qr/^pass the constant name as string/);
ok(!defined $fsize3);

my $fsize4;
eval { $fsize4 = ulimit(UL_GETFSIZE) };
like($@, qr/^pass the constant name as string/);
ok(!defined $fsize4);

use POSIX::1003::Limit qw(UL_SETFSIZE);

# On Linux, SET only seems to work when it is substantially smaller.
my $smaller = 12349895;
my $fsize5 = ulimit('UL_SETFSIZE', $smaller);
cmp_ok($fsize5, '==', $smaller, 'smaller fsize');
cmp_ok(UL_GETFSIZE, '==', $smaller);

use POSIX::1003::Limit qw(ulimit_names);

my @names = ulimit_names;
cmp_ok(scalar @names, '>=', 2, @names." names");

my $undefd = 0;
foreach my $name (sort @names)
{   my $val = $name =~ m/SET/ ? '(setter)' : ulimit($name);
    printf "  %4d %-40s %s\n", $ulimit{$name}, $name
       , (defined $val ? $val : 'undef');
    defined $val or $undefd++;
}
ok(1, "$undefd UL_ constants return undef");
