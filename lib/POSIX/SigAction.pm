# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

use warnings;
use strict;

no warnings 'redefine', 'prototype';  # during release of distribution

=package POSIX::SigAction

=chapter NAME

POSIX::SigAction - represent a struct sigaction

=chapter SYNOPSIS

  $sigset    = POSIX::SigSet->new(SIGINT, SIGQUIT);
  $sigaction = POSIX::SigAction
     ->new(\&handler, $sigset, SA_NOCLDSTOP);

  $sigset    = $sigaction->mask;
  $sigaction->flags(SA_RESTART);
  $sigaction->safe(1);

=chapter DESCRIPTION

The C<POSIX::SigAction> object corresponds to the C C<struct sigaction>,
defined by C<signal.h>.

This module is a bit tricky: POSIX.pm contains the same code for
the C<POSIX::SigAction> namespace. However, we do not need POSIX.pm
but only the POSIX.xs component which has the namespace hard-coded.

=chapter METHODS

=section Constructors

=c_method new $handler, [$sigset, [$flags]]
The first parameter is the handler, a code reference. The second parameter
is a M<POSIX::SigSet> object, it defaults to the empty set.  The third
parameter contains the C<sa_flags>, it defaults to 0.

This object will be destroyed automatically when it is no longer needed.
=cut

sub POSIX::SigAction::new
{   my $class = shift;
    bless {HANDLER => $_[0], MASK => $_[1], FLAGS => $_[2] || 0, SAFE => 0},
       $class;
}

#---------------------------
=section Accessors

=method handler 
=method mask 
=method flags 
Accessor functions to get/set the values of a SigAction object.

=method safe 
Accessor function for the "safe signals" flag of a SigAction object; see
L<perlipc> for general information on safe (a.k.a. "deferred") signals.  If
you wish to handle a signal safely, use this accessor to set the "safe" flag
in the C<POSIX::SigAction> object:

   $sigaction->safe(1);

You may also examine the "safe" flag on the output action object which is
filled in when given as the third parameter to
M<POSIX::1003::Signals::sigaction()>:

  sigaction(SIGINT, $new_action, $old_action);
  if ($old_action->safe) {
     # previous SIGINT handler used safe signals
  }
=cut

# We cannot use a "package" statement, because it confuses CPAN: the
# namespace is assigned to the perl core distribution.
no warnings 'redefine';
sub POSIX::SigAction::handler($;$)
{   $_[0]->{HANDLER} = $_[1] if @_ > 1; $_[0]->{HANDLER} }

sub POSIX::SigAction::mask($;$)
{   $_[0]->{MASK} = $_[1] if @_ > 1; $_[0]->{MASK} }

sub POSIX::SigAction::flags($;$)
{   $_[0]->{FLAGS} = $_[1] if @_ > 1; $_[0]->{FLAGS} }

sub POSIX::SigAction::safe($;$)
{   $_[0]->{SAFE} = $_[1] if @_ > 1; $_[0]->{SAFE} }

1;
