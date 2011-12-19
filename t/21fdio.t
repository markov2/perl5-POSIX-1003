#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 12;

use POSIX::1003::FdIO;   # load all
use Fcntl  qw(O_RDONLY SEEK_SET SEEK_CUR);

my $fd = openfd __FILE__, O_RDONLY
    or die "cannot open myself: $!";
ok(defined $fd, "open file, fd = $fd");

cmp_ok(seekfd($fd, 0,  SEEK_SET), '==', 0,  'tell');
cmp_ok(seekfd($fd, 10, SEEK_SET), '==', 10, 'tell');
cmp_ok(seekfd($fd, 0,  SEEK_CUR), '==', 10, 'tell');

# try to read a few bytes
my $string;
my $len = readfd $fd, $string, 20;
ok(defined $string, "read string '$string'");
cmp_ok($len, '==', 20, 'returned length');
cmp_ok(length $string, '==', 20, 'check length');
cmp_ok(seekfd($fd, 0,  SEEK_CUR), '==', 30, 'tell');
cmp_ok(tellfd($fd), '==', 30, 'tellfd');

my $readall = readfd_all $fd;
ok(defined $readall, "read all success");
cmp_ok((-s __FILE__) - 30, '==', length $readall, "all bytes");

# try to read the whole file, from here on
ok((closefd($fd) ? 1 : 0), "closefd $fd");
