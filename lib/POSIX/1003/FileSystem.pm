use warnings;
use strict;

package POSIX::1003::FileSystem;
use base 'POSIX::1003';

# Blocks resp from unistd.h, stdio.h, limits.h
my @constants = qw/
 F_OK W_OK X_OK R_OK

 FILENAME_MAX

 LINK_MAX MAX_CANON NAME_MAX PATH_MAX
 /;

# POSIX.xs defines L_ctermid L_cuserid L_tmpname: useless!

# Blocks resp from sys/stat.h, unistd.h
my @functions = qw/
 mkfifo

 access lchown
 /;

our @EXPORT_OK   = (@constants, @functions);
our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 );

=chapter NAME

POSIX::1003::FileSystem - POSIX for the file-system

=chapter SYNOPSIS

  use POSIX::1003::FileSystem qw(access R_OK);
  if(access($fn, R_OK)) # $fn is readible?

=chapter DESCRIPTION
You may also need M<POSIX::1003::Pathconf>.

=chapter CONSTANTS

=section Constants from unistd.h

To be used with M<access()>

 F_OK          File exists
 R_OK          is readable for me
 W_OK          is writable for mee
 X_OK          is executable for me

=section Constants from limits.h

 FILENAME_MAX  Maximum length of a filename

=section Constants from stdio.h

 LINK_MAX      Maximum number of hard-links
 MAX_CANON
 NAME_MAX
 PATH_MAX
 TMP_MAX       The minimum number of unique filenames generated
               by tmpnam (and tempnam when it uses tmpnam's name-
               space), or tempnam (the two are separate).

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

  use POSIX::1003::FileSystem 'lchown';
  my @successes = lchown($uid, $gid, @filenames);
=cut

sub lchown($$@)
{   my ($uid, $gid) = (shift, shift);
    my $successes = 0;
    POSIX::lchown($uid, $gid, $_) && $successes++ for @_;
    $successes;
}

1;
