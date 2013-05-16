use warnings;
use strict;

package POSIX::1003::User;
use base 'POSIX::1003::Module';

my @constants = qw/
 /;

our @IN_CORE  = qw/
  getpwnam  getpwuid  getpwent
  getgrnam  getgrgid  getgrent
  getlogin
  /;

my @functions = qw/
  getuid    setuid
  geteuid   seteuid
            setreuid
  getresuid setresuid

  getgid    setgid
  getegid   setegid
            setregid
  getresgid setresgid
  getgroups setgroups
  /;

push @functions, @IN_CORE;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  );

=chapter NAME

POSIX::1003::User - POSIX handling user and groups

=chapter SYNOPSIS

  use POSIX::1003::User;

=chapter DESCRIPTION

=chapter FUNCTIONS

=section Standard POSIX

User and group management is provided via many functions, which are
not portable either in implementation or in availability.
See also L<http://www.cs.berkeley.edu/~daw/papers/setuid-usenix02.pdf>

=cut

#------------------
=subsection Get/set users

The implementation of M<setuid()> differs per platform.  M<seteuid()>
is more consistent and widely available.  M<setresuid()> is the most
powerful, but not everywhere.  Functions which are not implemented
will return error ENOSYS.

=examples
 my $uid = getuid();
 defined $uid or die $!;

 setuid($uid)
    or die "cannot set uid to $uid: $!\n";

 my ($ruid, $euid, $suid) = getresuid;
 defined $ruid or die $!;

 setresuid($ruid, $euid, $suid)
    or die $!;

=function getuid
=function setuid UID
=function geteuid
=function seteuid EUID
=function setreuid RUID, EUID
=function getresuid 
=function setresuid RUID, EUID, SUID

#------------------
=subsection Get/set groups

The same use and limitations as the uid functions.

=examples
  # see also the set*uid examples above
  my @mygroups = getgroups();
  @mygroups or die $!;

  setgroups(1,2,3) or die $!;

=function getgid
=function setgid GID
=function getegid
=function setegid EGID
=function setregid RGID, EGID
=function getresgid 
=function setresgid RGID, EGID, SGID

=function getgroups
Returns a list of group-ids, which may (or may not) contain the effective
group-id.
=cut

#------------------
=subsection Information about users

=function getpwuid USERID
Simply L<perlfunc/getpwuid>
=example
  my ($name, $passwd, $uid, $gid, $quota, $comment,
      $gcos, $dir, $shell, $expire) = getpwuid($uid);
  my $uid  = getpwnam($username);
  my $name = getpwuid($userid);

=function getpwnam USERNAME
Simply L<perlfunc/getpwnam>

=function getpwent
Simply L<perlfunc/getpwent>

=function getlogin
The username associated with the controling terminal.
Simply L<perlfunc/getlogin>
=cut

=subsection Information about groups

=function getgrgid GROUPID
Simply L<perlfunc/getgrgid>

=function getgrnam GROUPNAME
Simply L<perlfunc/getgrnam>

=function getgrent
Simply L<perlfunc/getgrent>

=cut

1;
