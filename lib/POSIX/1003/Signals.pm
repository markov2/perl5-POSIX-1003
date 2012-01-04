use warnings;
use strict;

package POSIX::1003::Signals;
use base 'POSIX::1003';

my @signals;
my @states  = qw/
 SIG_BLOCK SIG_DFL SIG_ERR
 SIG_IGN SIG_SETMASK SIG_UNBLOCK
 /;

my @actions = qw/
 SA_NOCLDSTOP SA_NOCLDWAIT SA_NODEFER SA_ONSTACK SA_RESETHAND SA_RESTART
 SA_SIGINFO
 /;

my @functions = qw/
 raise sigaction signal sigpending sigprocmask sigsuspend signal
 signal_names
 /;

my @constants = (@signals, @states, @actions);

our %EXPORT_TAGS =
  ( signals   => \@signals
  , actions   => \@actions
  , status    => \@states
  , constants => \@constants
  , functions => \@functions
  , table     => [ '%signals' ]
  );

our @IN_CORE = qw/kill/;

my $signals;
our %signals;

BEGIN {
    # initialize the :signals export tag
    $signals = signals_table;
    push @constants, keys %$signals;
    push @signals,   keys %$signals;
    tie %signals, 'POSIX::1003::ReadOnlyTable', $signals;
}

=chapter NAME

POSIX::1003::Signals - POSIX using signals

=chapter SYNOPSIS

  use POSIX::1003::Signals qw(:functions SIGPOLL SIGHUP);
  sigaction($signal, $action, $oldaction);
  sigpending($sigset);
  sigprocmask($how, $sigset, $oldsigset)
  sigsuspend($signal_mask);

  kill SIGPOLL//SIGHUP, $$;

  use POSIX::1003::Signals '%signals';
  my $number = $signals{SIGHUP};
  $signals{SIGNEW} = $number;

=chapter DESCRIPTION
This manual page explains the access to the POSIX C<sigaction>
functions and its relatives. This module uses two helper objects:
M<POSIX::SigSet> and M<POSIX::SigAction>.

=chapter FUNCTIONS
These functions are implemened in POSIX.xs

=section Standard POSIX

=function sigaction SIGNAL, ACTION, [OLDACTION]

Detailed signal management.  The C<signal> must be a number (like SIGHUP),
not a string (like "SIGHUP").  The  C<action> and C<oldaction> arguments
are C<POSIX::SigAction> objects. Returns C<undef> on failure. 

If you use the C<SA_SIGINFO flag>, the signal handler will in addition to
the first argument (the signal name) also receive a second argument: a
hash reference, inside which are the following keys with the following
semantics, as defined by POSIX/SUSv3:

  signo   the signal number
  errno   the error number
  code    if this is zero or less, the signal was sent by
          a user process and the uid and pid make sense,
          otherwise the signal was sent by the kernel

The following are also defined by POSIX/SUSv3, but unfortunately
not very widely implemented:

  pid     the process id generating the signal
  uid     the uid of the process id generating the signal
  status  exit value or signal for SIGCHLD
  band    band event for SIGPOLL

A third argument is also passed to the handler, which contains a copy
of the raw binary contents of the siginfo structure: if a system has
some non-POSIX fields, this third argument is where to unpack() them
from.

Note that not all siginfo values make sense simultaneously (some are
valid only for certain signals, for example), and not all values make
sense from Perl perspective.

=function sigpending SIGSET

Examine signals that are blocked and pending.  This uses C<POSIX::SigSet>
objects for the C<sigset> argument.  Returns C<undef> on failure.

=function sigprocmask HOW, SIGSET, [OLDSIGSET]

Change and/or examine calling process's signal mask.  This uses
C<POSIX::SigSet> objects for the C<sigset> and C<oldsigset> arguments.
Returns C<undef> on failure.

Note that you can't reliably block or unblock a signal from its own signal
handler if you're using safe signals. Other signals can be blocked or
unblocked reliably.

=function sigsuspend SIGSET

Install a signal mask and suspend process until signal arrives.
This uses C<POSIX::SigSet> objects for the C<signal_mask> argument.
Returns C<undef> on failure.

=function raise SIGNAL
Send a signal to the executing process.
=cut

# Perl does not support pthreads, so:
sub raise($) { CORE::kill $_[0], $$ }

=function kill SIGNAL, PROCESS
Simply L<perlfunc/kill>.

B<Be warned> the order of parameters is reversed in the C<kill>
exported by M<POSIX>!

  CORE::kill($signal, $pid);
  ::Signals::kill($signal, $pid);
  POSIX::kill($pid, $signal);

=function signal SIGNAL, (CODE|'IGNORE'|'DEFAULT')
Set the CODE (subroutine reference) to be called when the SIGNAL appears.
See L<perlvar/%SIG>.

   signal(SIGINT, \&handler);
   $SIG{SIGINT} = \&handler;  # same
=cut

sub sigaction($$;$)   {goto &POSIX::sigaction }
sub sigpending($)     {goto &POSIX::sigpending }
sub sigprocmask($$;$) {goto &POSIX::sigprocmask }
sub sigsuspend($)     {goto &POSIX::sigsuspend }
sub signal($$)        { $SIG{$_[0]} = $_[1] }

#--------------------------
=section Additional

=function signal_names
Returns a list with all known names, unsorted.
=cut

sub signal_names() { keys %$signals }

#--------------------------

=chapter CONSTANTS

=over 4
=item B<%signals>
This exported variable is a (tied) HASH which maps C<SIG*> names
to their numbers.
=back

The following constants are exported, shown here with the values
discovered during installation of this module:

=for comment
#TABLE_SIGNALS_START

The constant names for this math module are inserted here during
installation.

=for comment
#TABLE_SIGNALS_END

=cut

sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $signals->{$name};
    sub() {$val};
}

1;
