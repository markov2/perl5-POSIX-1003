use warnings;
use strict;

package POSIX::1003::Socket;
use base 'POSIX::1003::Module';

use Carp    'croak';
use IO::Socket::IP;

my (@sock, @sol, @so, @af, @pf, @constants);
my @functions    = qw/socket_names/;
our @IN_CORE     = qw//;   # too be added

our %EXPORT_TAGS =
  ( sock      => \@sock
  , so        => \@so
  , sol       => \@sol
  , af        => \@af
  , pf        => \@pf
  , constants => \@constants
  , functions => \@functions
  , tables    => [ qw/%sockets/ ]
  );

my ($socket, %socket);
BEGIN {
    $socket    = socket_table;
    @constants = sort keys %$socket;
    tie %socket, 'POSIX::1003::ReadOnlyTable', $socket;

    @sock      = grep /^SOCK/, @constants;
    @so        = grep /^SO_/,  @constants;
    @sol       = grep /^SOL_/, @constants;
    @af        = grep /^AF_/,  @constants;
    @pf        = grep /^PF_/,  @constants;
}

=chapter NAME

POSIX::1003::Socket - POSIX constants and functions related to sockets

=chapter SYNOPSIS

  # SOCKET support

  use POSIX::1003::Socket; # load all names
  socket(Server, PF_INET, SOCK_STREAM, $proto);
  setsockopt(Server, SOL_SOCKET, SO_REUSEADDR, 1);

  use POSIX::1003::Socket qw(SOCK_DGRAM);
  print SOCK_DGRAM;        # constants are subs

  use POSIX::1003::Socket '%socket';
  my $bits = $socket{SOCK_DGRAM};
  $socket{SOCK_DGRAM} = $bits;

  print "$_\n" for keys %socket;

=chapter DESCRIPTION
[added in release 0.99]
This module provides access to the "socket" interface, especially a
long list of constants starting with C<SO_>, C<SOL_>, C<SOCK_>, C<AF_>,
and many more.

The best way to work with sockets is via M<Socket>, M<IO::Socket> or
M<IO::Socket::INET>.  This module provides many more constants than
those modules do, but currently does not export the functions as the
other modules of this suite do.

The advantage of using the constants of this module, is that the list
will be extended when new names are discovered, and then immediately
available to older versions of Perl.

=chapter METHODS
=cut

sub exampleValue($)
{   my ($class, $name) = @_;
    $socket{$name} // 'undef';
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $nr = $socket->{$name} // return sub() {undef};
    sub() {$nr};
}

=chapter FUNCTIONS

=section Standard POSIX

Many socket related functions are contained in Perl's core.

=method getsockopt $socket, $level, $opt
Returns the value for $opt (some SO_ constant).  See also M<setsockopt()>.

=method setsockopt $socket, $level, $opt, $value
Set the $value on $opt for the $socket.

There are a few minor tricks to make this function integrate better in
Perl.  Firstly, for the boolean OPTs C<SO_DONTROUTE>, C<SO_KEEPALIVE>,
and C<SO_REUSEADDR> the value is treated as a real Perl boolean.

C<SO_LINGER> has three combinations.  "Linger off" is reprensed by 
Other values mean "linger on" with a timeout.
C<SO_RCVTIMEO> and C<SO_SNDTIME> get a timestamp in float.

=cut

# get/setsockopt in XS

=section Additional

=function socket_names 
Returns a list with all known names, unsorted.
=cut

sub socket_names() { keys %$socket }

=chapter CONSTANTS

=over 4
=item B<%socket>
This exported variable is a tied HASH which maps C<SO*> and C<AF_*>
names to numbers, to be used with various socket related functions.

=back

The following constants where detected on your system when the module
got installed.  The second column shows the value which where returned
at that time.

=section export tag :so

=for comment
#TABLE_SOCKET_SO_START

   If you install the module, the table will be filled-in here

=for comment
#TABLE_SOCKET_SO_END

=section export tag :sol

=for comment
#TABLE_SOCKET_SOL_START

   If you install the module, the table will be filled-in here

=for comment
#TABLE_SOCKET_SOL_END

=section export tag :sock

=for comment
#TABLE_SOCKET_START

   If you install the module, the table will be filled-in here

=for comment
#TABLE_SOCKET_END

=section export tag :af

=for comment
#TABLE_SOCKET_AF_START

   If you install the module, the table will be filled-in here

=for comment
#TABLE_SOCKET_AF_END

=section export tag :pf

=for comment
#TABLE_SOCKET_PF_START

   If you install the module, the table will be filled-in here

=for comment
#TABLE_SOCKET_PF_END

=cut

1;
