# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::User;
use base 'POSIX::1003::Module';

use warnings;
use strict;

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

my @constants;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%user' ]
  );

my  $user;
our %user;

BEGIN {
    $user = user_table;
    push @constants, keys %$user;
    tie %user, 'POSIX::1003::ReadOnlyTable', $user;
}

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
=function setuid $uid
=function geteuid 
=function seteuid $euid
=function setreuid $ruid, $euid
=function getresuid 
=function setresuid $ruid, $euid, $suid
=cut

#------------------
=subsection Get/set groups

The same use and limitations as the uid functions.

=examples
  # see also the set*uid examples above
  my @mygroups = getgroups();
  @mygroups or die $!;

  setgroups(1,2,3) or die $!;

=function getgid 
=function setgid $gid
=function getegid 
=function setegid $egid
=function setregid $rgid, $egid
=function getresgid 
=function setresgid $rgid, $egid, $sgid

=function getgroups 
Returns a list of group-ids, which may (or may not) contain the effective
group-id.
=cut

#------------------
=subsection Information about users

=function getpwuid $userid
Simply L<perlfunc/getpwuid>
=example
  my ($name, $passwd, $uid, $gid, $quota, $comment,
      $gcos, $dir, $shell, $expire) = getpwuid($uid);
  my $uid  = getpwnam($username);
  my $name = getpwuid($userid);

=function getpwnam $username
Simply L<perlfunc/getpwnam>

=function getpwent 
Simply L<perlfunc/getpwent>

=function getlogin 
The username associated with the controling terminal.
Simply L<perlfunc/getlogin>
=cut

=subsection Information about groups

=function getgrgid $groupid
Simply L<perlfunc/getgrgid>

=function getgrnam $groupname
Simply L<perlfunc/getgrnam>

=function getgrent 
Simply L<perlfunc/getgrent>

=cut

1;
