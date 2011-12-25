use warnings;
use strict;

package POSIX::1003::FS;
use base 'POSIX::1003';

# Blocks resp from unistd.h, stdio.h, limits.h
my @constants = qw/
 F_OK W_OK X_OK R_OK

 FILENAME_MAX

 LINK_MAX MAX_CANON NAME_MAX PATH_MAX
 /;

# POSIX.xs defines L_ctermid L_cuserid L_tmpname: useless!

# Blocks resp from sys/stat.h, unistd.h, utime.h, sys/types
my @functions = qw/
 mkfifo mknod

 access lchown

 utime

 major minor makedev
 /;

our @IN_CORE     = qw(utime);

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 );

=chapter NAME

POSIX::1003::FS - POSIX for the file-system

=chapter SYNOPSIS

  use POSIX::1003::FS qw(access R_OK);
  if(access($fn, R_OK)) # $fn is readible?

  use POSIX::1003::FS qw(mkfifo);
  use Fcntl ':mode';
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

=chapter CONSTANTS

The following constants are exported, shown here with the values
discovered during installation of this module:

=for comment
#TABLE_FSYS_START

The constant names for this math module are inserted here during
installation.

=for comment
#TABLE_FSYS_END

=cut

1;
