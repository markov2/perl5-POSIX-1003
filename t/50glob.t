#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More;

use POSIX::1003::FS     qw/posix_glob GLOB_NOMATCH/;
use POSIX::1003::Errno  qw/EACCES/;

$^O ne 'MSWin32'
    or plan skip_all => 'tests unix specific';

plan tests => 8;

my ($err, $fns) = posix_glob('/etc/a*');
#warn "  f=$_\n" for @$fns;
ok(!$err, 'ran glob');
cmp_ok(scalar @$fns, '>', 2, 'found filenames');
like($fns->[0], qr!^/etc/a!, "match $fns->[0]");

my ($err2, $fns2) = posix_glob('/xx');
cmp_ok($err2, '==', GLOB_NOMATCH);
cmp_ok(scalar @$fns2, '==', 0);

mkdir '/tmp/aa';
chmod 0, '/tmp/aa';
my $called;
my ($err3, $fns3) = posix_glob('/tmp/aa/*', on_error => sub{$called="@_"; 0});
#warn "($err3, @$fns3)\n";
rmdir '/tmp/aa';
ok(defined $called, 'call on error');
is($called, '/tmp/aa '.EACCES);
cmp_ok($err3, '==', GLOB_NOMATCH);
