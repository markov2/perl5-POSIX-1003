use warnings;
use strict;

package POSIX::1003::FS;
use base 'POSIX::1003::Module';

# Blocks resp from unistd.h, stdio.h, limits.h
my @constants;
my @access = qw/access/;
my @stat   = qw/stat lstat mkfifo mknod mkdir lchown
  S_ISDIR S_ISCHR S_ISBLK S_ISREG S_ISFIFO S_ISLNK S_ISSOCK S_ISWHT
/;
my @glob = qw/posix_glob/;  # fnmatch

sub S_ISDIR($)  { ($_[0] & S_IFMT()) == S_IFDIR()}
sub S_ISCHR($)  { ($_[0] & S_IFMT()) == S_IFCHR()}
sub S_ISBLK($)  { ($_[0] & S_IFMT()) == S_IFBLK()}
sub S_ISREG($)  { ($_[0] & S_IFMT()) == S_IFREG()}
sub S_ISFIFO($) { ($_[0] & S_IFMT()) == S_IFIFO()}
sub S_ISLNK($)  { ($_[0] & S_IFMT()) == S_IFLNK()}
sub S_ISSOCK($) { ($_[0] & S_IFMT()) == S_IFSOCK()}
sub S_ISWHT($)  { ($_[0] & S_IFMT()) == S_IFWHT()}  # FreeBSD

# POSIX.xs defines L_ctermid L_cuserid L_tmpname: useless!

my @functions = qw/
 mkfifo mknod stat lstat rename
 access lchown
 utime
 major minor makedev
 /;

our @IN_CORE     = qw(utime mkdir stat lstat rename);

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 , access    => \@access
 , stat      => \@stat
 , glob      => \@glob
 , tables    => [ qw/%access %stat/ ]
 );

my ($fsys, %access, %stat, %glob);

BEGIN {
    $fsys = fsys_table;
    push @constants, keys %$fsys;

    # initialize the :access export tag
    push @access, grep /_OK$|MAX/, keys %$fsys;
    my %access_subset;
    @access_subset{@access} = @{$fsys}{@access};
    tie %access,  'POSIX::1003::ReadOnlyTable', \%access_subset;

    # initialize the :stat export tag
    push @stat, grep /^S_I/, keys %$fsys;
    my %stat_subset;
    @stat_subset{@stat} = @{$fsys}{@stat};
    tie %stat, 'POSIX::1003::ReadOnlyTable', \%stat_subset;

    # initialize the :fsys export tag
    push @glob, grep /^(?:GLOB|FNM|WRDE)_/, keys %$fsys;
    my %glob_subset;
    @glob_subset{@glob} = @{$fsys}{@glob};
    tie %glob, 'POSIX::1003::ReadOnlyTable', \%glob_subset;
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

=function mkfifo $filename, $mode

=function access $filename, $flags
Read C<man filetest> before you start using this function!
Use the C<*_OK> constants for $flags.

=function lchown $uid, $gid, $filenames
Like C<chown()>, but does not follow symlinks when encountered. Returns
the number of files successfully changed.

B<Be Warned> that the M<POSIX> specification uses different parameter
order. For Perl was decided to accept a list of filenames.  Passing more
than one filename, however, hinders correct error reporting.

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

=function utime $atime, $mtime, $filenames
Simply C<CORE::utime()>

B<Be Warned> that C<POSIX.pm> uses a different parameter order than CORE.

  POSIX::utime($filename, $atime, $mtime);
  CORE::utime($atime, $mtime, @filenames);

=function stat [$fh|$fn|$dirfh]
Simply C<CORE::stat()>.  See also M<lstat()>

=function lstat [$fh|$fn|$dirfh]
Simply C<CORE::lstat()>.  See also M<stat()>

=function mknod $path, $mode, $device
Create a special device node on $path. Useful symbols for $mode can be
collected from M<Fcntl> (import tag C<:mode>).  The $device number is
a combination from the type (I<major> number), a sequence number and
usage information (combined in a I<minor> number).

=function mkdir [$filename [$mask]]
Simple C<CORE::mkdir()>

=function rename $oldname, $newname
[0.93] Give a file or directory a new name, the basis of the UNIX C<mv>
('move') command.  This will use C<CORE::rename()>. 

B<Be warned> that Window's C<rename> implementation will fail when
$newname exists.  That behavior is not POSIX compliant.  On many platforms
(especially the older), a C<rename> between different partitions is not
allowed.

=function glob $pattern|\@patterns, %options
Returns a list of file and directory names which match the $pattern
(or any of the @patterns), using the libc implementation of glob().
Various system shells (sh, bash, tsh, etc) use this same function with
different flags.  This function provides any possible combination.

B<BE WARNED> that function returns bytes: file names are B<not
printable strings> because the encoding used for file names on disk is
not defined (on UNIXes).  Read more in L</Filenames to string>

=option  flags INTEGER
=default flags GLOB_NOSORT|GLOB_NOESCAPE|GLOB_BRACE
There are many interesting flags to tune the expansion.  Sorting should
happen in a locale context, so there is no use having glob() do it on
bytes.  GLOB_APPEND will be used automatically, when needed.  GLOB_DOOFFS
cannot be used (not needed)

=option   unique BOOLEAN
=default  unique <false>
When you use patterns which overlap, you may want to remove doubles.
Still, this happens on bytes... there is a possibility that different
byte strings display the same in utf8 space.

=option   on_error CODE
=default  on_error C<undef>
What to do when an error is encountered.  The CODE will be called with
the path causing the problem, and its error code.  This is B<not
thread safe>
=cut

sub posix_glob($%)
{   my ($patterns, %args) = @_;
    my $flags  = $args{flags}
       // $glob{GLOB_NOSORT}|$glob{GLOB_NOESCAPE}|$glob{GLOB_BRACE};
    my $errfun = $args{on_error} || sub {0};

    my ($err, @fns);
    if(ref $patterns eq 'ARRAY')
    {   foreach my $pattern (@$patterns)
        {   my $thiserr = _glob(@fns, $pattern, $flags, $errfun);
            next if !$thiserr || $thiserr==$glob{GLOB_NOMATCH};

            $err = $thiserr;
            last;
        }
    }
    else
    {   $err = _glob(@fns, $patterns, $flags, $errfun);
    }

    if($args{unique} && @fns)
    {   my %seen;
        @fns = grep !$seen{$_}++, @fns;
    }

    $err //= @fns ? $glob{GLOB_NOMATCH} : 0;
    ($err, \@fns);
}

#---------
=section Additional

=function major $device
=function minor $device
=function makedev $major, $minor
Combine $major and $minor into a single DEVICE number.

 my $device      = (stat $filename)[6];
 my $device_type = major $device;
 my $sequence_nr = minor $device;

 my $device = makedev $major, $minor;
 mknod $specialfile, $mode, $device;

=function S_ISDIR $mode
=example
  use File::stat 'stat';
  if(S_ISDIR(stat($fn)->mode)) ...

  if(S_ISDIR((lstat $fn)[2])) ...

=function S_ISCHR $mode
=function S_ISBLK $mode
=function S_ISREG $mode
=function S_ISFIFO $mode
=function S_ISLNK $mode
=function S_ISSOCK $mode
=function S_ISWHT $mode
=function S_ISVTX $mode

=chapter CONSTANTS

The following constants are exported, shown here with the values
discovered during installation of this module.  When you ask for
C<:constants>, you get all, but they are also grouped by tag.

=section export tag :stat
Export M<stat()> and M<lstat()> including their related constants.
Besides, the node related functions M<mkfifo()>, M<mknod()>, M<mkdir()>,
and M<lchown()>.  Also, the common C<S_IS*> C-level macro are provided
as function.

=for comment
#TABLE_FSYS_STAT_START

  During installation, a symbol table will get inserted here.

=for comment
#TABLE_FSYS_STAT_END

=section export tag :access
Exports function M<access()> plus its related constants.

=for comment
#TABLE_FSYS_ACC_START

  During installation, a symbol table will get inserted here.

=for comment
#TABLE_FSYS_ACC_END

=section export tag :glob
The M<glob()> and M<fnmatch()> related constants.

=for comment
#TABLE_FSYS_GLOB_START

  During installation, a symbol table will get inserted here.

=for comment
#TABLE_FSYS_GLOB_END

=cut

sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $fsys->{$name};
    sub() {$val};
}

1;
