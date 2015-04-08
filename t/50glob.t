#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More;

use POSIX::1003::FS     qw/posix_glob GLOB_NOMATCH GLOB_MARK/;
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

my ($err3, $fns3) = posix_glob('/tmp/aa');
diag("1: $err3, @$fns3");

($err3, $fns3) = posix_glob('/tmp/aa', flags => GLOB_MARK);
diag("2: $err3, @$fns3");

my ($callfn, $callerr);
my ($err4, $fns4) = posix_glob('/tmp/aa/*'
  , on_error => sub { ($callfn, $callerr) = @_; 0});
#warn "($err4, @$fns4)\n";
rmdir '/tmp/aa';
like($callfn, qr!^/tmp/aa/?$!, 'error fn');
cmp_ok($callerr, '==', EACCES, 'error rc');
cmp_ok($err4, '==', GLOB_NOMATCH);
