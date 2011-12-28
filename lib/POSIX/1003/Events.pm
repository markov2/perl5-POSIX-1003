use warnings;
use strict;

package POSIX::1003::Events;
use base 'POSIX::1003';

my @constants;
my @functions = qw/
 FD_CLR FD_ISSET FD_SET FD_ZERO 
 select poll
 /;

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 );

my  $poll;
our %poll;

BEGIN {
    $poll = poll_table;
    push @constants, keys %$poll;
}

=chapter NAME

POSIX::1003::Events - POSIX for the file-system

=chapter SYNOPSIS

  use POSIX::1003::Events;

=chapter DESCRIPTION

=chapter FUNCTIONS

=function select RBITS, WBITS, EBITS, [TIMEOUT]
Perl core contains two functions named C<select>.  The second is the
one we need here.  Without TIMEOUT, the select will wait until an event
emerges (or an interrupt).

In the example below, C<$rin> is a bit-set indicating on which
file-descriptors should be listed for read events (I<data available>)
and C<$rout> is a sub-set of that. The bit-sets can be manipulated
with the C<FD_*> functions also exported by this module.

  my ($nfound, $timeleft) =
    select($rout=$rin, $wout=$win, $eout=$ein, $timeout);

  my $nfound = select($rout=$rin, $wout=$win, $eout=$ein);

The C<select> interface is inefficient when used with many filehandles.
You can better use M<poll()>.
=cut

sub select($$$;$)
{   push @_, undef if @_==3;
    goto &select;
}

=function FD_CLR FD, SET
Remove the file descriptor FD from the SET. If FD is not a member of
this set, there shall be no effect on the set, nor will an error be
returned.

=function FD_ISSET FD, SET
Returns true if the file descriptor FD is a member of the SET

=function FD_SET FD, SET
Add the file descriptor FD to the SET
If the file descriptor FD is already in this set, there
is no effect on the set, nor will an error be returned.

=function FD_ZERO SET
Clear the set
=cut

sub FD_CLR($$)   {vec($_[1],$_[0],1) = 0}
sub FD_ISSET($$) {vec($_[1],$_[0],1) ==1}
sub FD_SET($$)   {vec($_[1],$_[0],1) = 1}
sub FD_ZERO($)   {$_[0] = 0}

=function poll HASH, [TIMEOUT]
If TIMEOUT is not defined, the poll will wait until something
happend.  When C<undef> is returned, then there is an error.
With an empy HASH returned, then the poll timed out.  Otherwise,
the returned HASH contains the FDs where something happened.
=cut

sub poll($;$)
{   my ($data, $timeout) = @_;
    defined $timeout or $timeout = -1;
    _poll($data, $timeout);
}

=chapter CONSTANTS

The following constants where detected on your system when the
module got installed.  The second column shows the value which
where returned at that time.

=for comment
#TABLE_POLL_START

   If you install the module, the table will be filled-in here

=for comment
#TABLE_POLL_END

=cut

1;
