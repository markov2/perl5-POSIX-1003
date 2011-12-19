use warnings;
use strict;

package POSIX::SigAction;

=chapter NAME

POSIX::1003::SigAction - represent a struct sigaction

=chapter SYNOPSIS

  $sigset    = POSIX::SigSet->new(SIGINT, SIGQUIT);
  $sigaction = POSIX::1003:SigAction
     ->new(\&handler, $sigset, SA_NOCLDSTOP);

  $sigset    = $sigaction->mask;
  $sigaction->flags(SA_RESTART);
  $sigaction->safe(1);

=chapter DESCRIPTION

The C<POSIX::1003::SigAction> object corresponds to the C
C<struct sigaction>, defined by C<signal.h>.

=chapter METHODS

=section Constructors

=c_method new HANDLER, [SIGSET, [FLAGS]]
The first parameter is the handler, a code reference. The second parameter
is a M<POSIX::SigSet> object, it defaults to the empty set.  The third
parameter contains the C<sa_flags>, it defaults to 0.

This object will be destroyed automatically when it is no longer needed.  
=cut

sub new
{   my $class = shift;
    bless {HANDLER => $_[0], MASK => $_[1], FLAGS => $_[2] || 0, SAFE => 0},
       $class;
}

=section Other

=method handler
=method mask
=method flags
Accessor functions to get/set the values of a SigAction object.

=method safe
Accessor function for the "safe signals" flag of a SigAction object; see
L<perlipc> for general information on safe (a.k.a. "deferred") signals.  If
you wish to handle a signal safely, use this accessor to set the "safe" flag
in the C<POSIX::1003::SigAction> object:

   $sigaction->safe(1);

You may also examine the "safe" flag on the output action object which is
filled in when given as the third parameter to M<POSIX::1003::sigaction()>:

  sigaction(SIGINT, $new_action, $old_action);
  if ($old_action->safe) {
     # previous SIGINT handler used safe signals
  }
=cut

sub handler { $_[0]->{HANDLER} = $_[1] if @_ > 1; $_[0]->{HANDLER} };
sub mask    { $_[0]->{MASK}    = $_[1] if @_ > 1; $_[0]->{MASK} };
sub flags   { $_[0]->{FLAGS}   = $_[1] if @_ > 1; $_[0]->{FLAGS} };
sub safe    { $_[0]->{SAFE}    = $_[1] if @_ > 1; $_[0]->{SAFE} };

1;
