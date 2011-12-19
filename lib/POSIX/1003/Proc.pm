use warnings;
use strict;

package POSIX::1003::Proc;
use base 'POSIX::1003';

# Blocks resp. in stdlib.h, limits.h
my @constants = qw/
 EXIT_FAILURE EXIT_SUCCESS

 CHILD_MAX
 /;

our @IN_CORE   = qw/wait waitpid/;

# Blocks resp. in stdlib.h, sys/wait.h, unistd.h
my @functions = qw/
 abort

 WEXITSTATUS WIFEXITED WIFSIGNALED WIFSTOPPED
 WNOHANG WSTOPSIG WTERMSIG WUNTRACED
  
 _exit pause setpgid setsid tcgetpgrp tcsetpgrp
 ctermid cuserid getcwd nice
 /;
push @functions, @IN_CORE;

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 );

=chapter NAME

POSIX::1003::Proc - POSIX handling processes

=chapter SYNOPSIS

  use POSIX::1003::Proc qw/abort/;

=chapter DESCRIPTION
Functions which are bound to each separate process.

=chapter CONSTANTS

=section Constants from stdlib.h

 EXIT_FAILURE EXIT_SUCCESS

=section Constants from limits.h

 CHILD_MAX

=chapter FUNCTIONS

=section Standard POSIX functions from stdlib.h

=function abort
Abnormal process exit.

=section Standard POSIX functions from sys/wait.h

These functions have captial names because in C they are implemented
as macro's (which are capitalized by convension)

=function WIFEXITED $?
Returns true if the child process exited normally: "exit()" or by
falling off the end of "main()".

=function WEXITSTATUS $?
Returns the normal exit status of the child process. Only meaningful
if C<WIFEXITED($?)> is true.

=function WIFSIGNALED $?
Returns true if the child process terminated because of a signal.

=function WTERMSIG $?
Returns the signal the child process terminated for. Only meaningful
if C<WIFSIGNALED($?)> is true.

=function WIFSTOPPED $?
Returns true if the child process is currently stopped. Can happen only
if you specified the C<WUNTRACED> flag to waitpid().

=function WSTOPSIG $?
Returns the signal the child process was stopped for. Only meaningful
if C<WIFSTOPPED($?)> is true.

=function wait
Simply L<perlfunc/wait>.

=function waitpid PID
Simply L<perlfunc/waitpid>.
=cut

#-------------------------------------
=section Standard POSIX functions from unistd.h

=function cuserid
Get the login name of the effective user of the current process.
See also C<perldoc -f getlogin>
  my $name = cuserid();

=function ctermid
Generates the path name for the controlling terminal of this process.
  my $path = ctermid();

=function _exit CODE
Leave the program without calling handlers registered with C<atexit>
(which is not available in Perl)

=function pause
=function setpgid PID, PPID
=function setsid
=function tcgetpgrp FD
=function tcsetpgrp FD, PID
=cut

sub cuserid()     {goto &POSIX::cuserid}
sub ctermid()     {goto &POSIX::ctermid}
sub _exit($)      {goto &POSIX::_exit}
sub pause()       {goto &POSIX::pause}
sub setpgid($$)   {goto &POSIX::setpgid}
sub setsid()      {goto &POSIX::setsid}
sub cgetpgrp($)   {goto &POSIX::cgetpgrp}
sub tcsetpgrp($$) {goto &POSIX::tcsetpgrp}

=function nice INTEGER
  use POSIX::1003::Proc 'nice';
  $new_prio = nice($increment);
=cut

sub nice($)       {goto &POSIX::nice}

=function getcwd
Returns the name of the current working directory.  See also M<Cwd>.

=function times5
The CORE C<times()> function returns four values, conveniently converted
into seconds (float).  The M<POSIX> C<times()> returns five values in
clocktics. To disambique those two, we offer the POSIX function under
a slightly different name.

          ($user, $sys, $cuser, $csys) = CORE::times();
 ($elapse, $user, $sys, $cuser, $csys) = POSIX::times();
 ($elapse, $user, $sys, $cuser, $csys) = times5();


=cut

sub times5()      {goto &POSIX::times}

1;
