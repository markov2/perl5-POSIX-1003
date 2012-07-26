use warnings;
use strict;

package POSIX::1003::FS;
use base 'POSIX::1003';

# Blocks resp from unistd.h, stdio.h, limits.h
my @constants;
my @access = qw/access/;
my @stat_checks = qw/S_ISDIR S_ISCHR S_ISBLK S_ISREG S_ISFIFO
  S_ISLNK S_ISSOCK S_ISWHT/;
my @stat  = (qw/stat lstat/, @stat_checks);

sub S_ISDIR($)  { ($_[0] & S_IFMT()) == S_IFDIR()}
sub S_ISCHR($)  { ($_[0] & S_IFMT()) == S_IFCHR()}
sub S_ISBLK($)  { ($_[0] & S_IFMT()) == S_IFBLK()}
sub S_ISREG($)  { ($_[0] & S_IFMT()) == S_IFREG()}
sub S_ISFIFO($) { ($_[0] & S_IFMT()) == S_IFIFO()}
sub S_ISLNK($)  { ($_[0] & S_IFMT()) == S_IFLNK()}
sub S_ISSOCK($) { ($_[0] & S_IFMT()) == S_IFSOCK()}
sub S_ISWHT($)  { ($_[0] & S_IFMT()) == S_IFWHT()}  # FreeBSD

# POSIX.xs defines L_ctermid L_cuserid L_tmpname: useless!

# Blocks resp from sys/stat.h, unistd.h, utime.h, sys/types
my @functions = qw/
 mkfifo mknod stat lstat
 access lchown
 utime
 major minor makedev
 /;

our @IN_CORE     = qw(utime mkdir stat lstat);

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 , access    => \@access
 , stat      => \@stat
 , tables    => [ qw/%access %stat/ ]
 );

my ($fsys, %access, %stat);

BEGIN {
    $fsys = fsys_table;
    push @constants, keys %$fsys;

    # initialize the :access export tag
    push @access, grep /_OK$/, keys %$fsys;
    my %access_subset;
    @access_subset{@access} = @{$fsys}{@access};
    tie %access,  'POSIX::1003::ReadOnlyTable', \%access_subset;

    # initialize the :fsys export tag
    push @stat, grep /^S_/, keys %$fsys;
    my %stat_subset;
    @stat_subset{@stat} = @{$fsys}{@stat};
    tie %stat, 'POSIX::1003::ReadOnlyTable', \%stat_subset;
}

=chapter NAME

POSIX::1003::FS - POSIX for the file-system

=chapter SYNOPSIS

  use POSIX::1003::FS ':access';
  if(access $fn, R_OK) # $fn is readible?

  use POSIX::1003::FS qw(mkfifo :stat);
  mkfifo($path, S_IRUSR|S_IWUSR) or die $!;

  # Absorbed from Unix::Mknod
  use POSIX::1003::FS qw(mknod major minor makedev);
  use File::stat
  my $st    = stat '/dev/null';
  my $major = major $st->rdev;
  my $minor = minor $st->rdev;
  mknod '/tmp/special', S_IFCHR|0600, makedev($major,$minor+1);

=chapter DESCRIPTION
You may also need M<POSIX::1003::Pathconf>.

=chapter FUNCTIONS

=section Standard POSIX

=function mkfifo FILENAME, MODE

=function access FILENAME, FLAGS
Read C<man filetest> before you start using this function!
Use the C<*_OK> constants for FLAGS.

=function lchown UID, GID, FILENAMES
Like C<chown()>, but does not follow symlinks when encountered. Returns
the number of files successfully changed.

B<Warning>, M<POSIX> uses different parameter order:

  # POSIX specification:
  # int lchown(const char *path, uid_t owner, gid_t group);

  # Perl core implementation:
  my $successes = chown($uid, $gid, @filenames);

  use POSIX;
  POSIX::lchown($uid, $gid, $filename) or die $!;

  use POSIX::1003::FS 'lchown';
  my @successes = lchown($uid, $gid, @filenames);
=cut

sub lchown($$@)
{   my ($uid, $gid) = (shift, shift);
    my $successes = 0;
    POSIX::lchown($uid, $gid, $_) && $successes++ for @_;
    $successes;
}

=function utime ATIME, MTIME, FILENAMES
Simply C<CORE::utime()>

B<Warning,> C<POSIX.pm> uses a different parameter order than core.

  POSIX::utime($filename, $atime, $mtime);
  CORE::utime($atime, $mtime, @filenames);

=function mknod PATH, MODE, DEVICE
Create a special device node on PATH. Useful symbols for MODE can be
collected from M<Fcntl> (import tag C<:mode>).  The DEVICE number is
a combination from the type (I<major> number), a sequence number and
usage information (combined in a I<minor> number).

=function mkdir [FILENAME [MASK]]
Simple C<CORE::mkdir()>

=section Additional

=function major DEVICE
=function minor DEVICE
=function makedev MAJOR, MINOR
Combine MAJOR and MINOR into a single DEVICE number.

 my $device      = (stat $filename)[6];
 my $device_type = major $device;
 my $sequence_nr = minor $device;

 my $device = makedev $major, $minor;
 mknod $specialfile, $mode, $device;

=function S_ISDIR MODE
=example
  use File::stat 'stat';
  if(S_ISDIR(stat($fn)->mode)) ...

  if(S_ISDIR((lstat $fn)[2])) ...

=function S_ISCHR MODE
=function S_ISBLK MODE
=function S_ISREG MODE
=function S_ISFIFO MODE
=function S_ISLNK MODE
=function S_ISSOCK MODE
=function S_ISWHT MODE

=chapter CONSTANTS

The following constants are exported, shown here with the values
discovered during installation of this module:

=for comment
#TABLE_FSYS_START

The constant names for this math module are inserted here during
installation.

=for comment
#TABLE_FSYS_END

All functions and constants which start with C<S_*> can be imported
using the C<:stat> tag, including all related C<S_IF*> functions.
The C<*_OK> tags can be imported with C<:access> =cut
=cut

sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $fsys->{$name};
    sub() {$val};
}

1;
