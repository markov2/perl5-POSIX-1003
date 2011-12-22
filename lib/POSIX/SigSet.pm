use warnings;
use strict;
# Implemented in XS

=package POSIX::SigSet

=chapter NAME
POSIX::SigSet - collect signal flags

=chapter SYNOPSIS

  use POSIX::SigSet ();
  use POSIX::1003::Signals;

  $sigset = POSIX::SigSet->new;
  $sigset = POSIX::SigSet->new(SIGUSR1);
  $sigset->addset(SIGUSR2);
  $sigset->delset(SIGUSR2);
  $sigset->emptyset();
  $sigset->fillset();
  if( $sigset->ismember(SIGUSR1) ) { ... }

=chapter DESCRIPTION

The C<POSIX::SigSet> object is simple a collection of signal flags. The
object is administered in POSIX.xs.  See M<POSIX::SigAction> for
examples of its usage.

=chapter METHODS

=section Constructors

=c_method new [SIGNALS]
Create a new SigSet object. One or more SIGNALS can be added immediately.
The object will be destroyed automatically when it is no longer needed.

=section Other

=method addset SIGNAL
Add one signal to a SigSet object. Returns C<undef> on failure.

=method delset SIGNAL
Remove one signal from the SigSet object.
Returns C<undef> on failure.

=method emptyset
Initialize the SigSet object to be empty.  Returns C<undef> on failure.

=method fillset
Initialize the SigSet object to include all signals.  Returns C<undef>
on failure.

=method ismember
Tests the SigSet object to see if it contains a specific signal.

=example
  if($sigset->ismember(SIGUSR1)) {
      print "contains SIGUSR1\n";
  }

=cut

1;
