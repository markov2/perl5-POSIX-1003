# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Signals;
use base 'POSIX::1003::Module';

use warnings;
use strict;

my @functions = qw/
    raise sigaction signal sigpending sigprocmask sigsuspend signal
    signal_names strsignal
 /;

my (@handlers, @signals, @actions);
my @constants;

our %EXPORT_TAGS =
  ( signals   => \@signals
  , actions   => \@actions
  , handlers  => \@handlers
  , constants => \@constants
  , functions => \@functions
  , tables    => [ '%signals' ]
  );

our @IN_CORE = qw/kill/;

my $signals;
our %signals;

BEGIN {
    $signals = signals_table;

    push @constants, keys %$signals;
    push @handlers, grep /^SIG_/, keys %$signals;
    push @signals,  grep !/^SA_|^SIG_/, keys %$signals;
    push @actions,  grep /^SA_/, keys %$signals;

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

=function sigaction $signal, $action, [$oldaction]

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

=function sigpending $sigset

Examine signals that are blocked and pending.  This uses C<POSIX::SigSet>
objects for the C<sigset> argument.  Returns C<undef> on failure.

=function sigprocmask $how, $sigset, [$oldsigset]

Change and/or examine calling process's signal mask.  This uses
C<POSIX::SigSet> objects for the C<sigset> and C<oldsigset> arguments.
Returns C<undef> on failure.

Note that you can't reliably block or unblock a signal from its own signal
handler if you're using safe signals. Other signals can be blocked or
unblocked reliably.

=function sigsuspend $sigset

Install a signal mask and suspend process until signal arrives.
This uses C<POSIX::SigSet> objects for the C<signal_mask> argument.
Returns C<undef> on failure.

=function raise $signal
Send a signal to the executing process.
=cut

# Perl does not support pthreads, so:
sub raise($) { CORE::kill $_[0], $$ }

=function kill $signal, $process
Simply L<perlfunc/kill>.

B<Be warned> the order of parameters is reversed in the C<kill>
exported by M<POSIX>!

  CORE::kill($signal, $pid);
  ::Signals::kill($signal, $pid);
  POSIX::kill($pid, $signal);

=function signal $signal, <CODE|'IGNORE'|'DEFAULT'>
Set the CODE (subroutine reference) to be called when the $signal appears.
See L<perlvar/%SIG>.

   signal(SIGINT, \&handler);
   $SIG{SIGINT} = \&handler;  # same

=cut

sub sigaction($$;$)   {goto &POSIX::sigaction }
sub sigpending($)     {goto &POSIX::sigpending }
sub sigprocmask($$;$) {goto &POSIX::sigprocmask }
sub sigsuspend($)     {goto &POSIX::sigsuspend }
sub signal($$)        { $SIG{$_[0]} = $_[1] }

=function strsignal $signal
Returns a string reprentation of the $signal.  When the $signal is unknown,
a standard string is returned (never undef)
=cut

sub strsignal($)      { _strsignal($_[0]) || "Unknown signal $_[0]" }

#--------------------------
=section Additional

=function signal_names 
Returns a list with all known signal names, unsorted.
=cut

sub signal_names() { @signals }

=function sigaction_names 
Returns a list with all known sigaction names, unsorted.
=cut

sub sigaction_names() { @actions }

#--------------------------

=chapter CONSTANTS

=over 4
=item B<%signals>
This exported variable is a (tied) HASH which maps C<SIG*> and
C<SA_*> names to their numbers.
=back

=section Export tag C<:signals>

The following constants are exported, shown here with the values
discovered during installation of this module:

=for comment
#TABLE_SIGNALS_START

  During installation, a symbol table will get inserted here.


=for comment
#TABLE_SIGNALS_END

=section Export tag C<:actions>

=for comment
#TABLE_SIGACTIONS_START

  During installation, a symbol table will get inserted here.


=for comment
#TABLE_SIGACTIONS_END

=section Export tag C<:handlers>

=for comment
#TABLE_SIGHANDLERS_START

  During installation, a symbol table will get inserted here.

=for comment
#TABLE_SIGHANDLERS_END

=cut

sub exampleValue($)
{   my ($class, $name) = @_;
    my $val = $signals->{$name};
    defined $val ? $val : 'undef';
}


sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $signals->{$name};
    sub() {$val};
}

1;
