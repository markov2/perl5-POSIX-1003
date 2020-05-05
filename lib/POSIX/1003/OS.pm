# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::OS;
use base 'POSIX::1003::Module';

use warnings;
use strict;

my @constants;
my @functions = qw/uname/;

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 , tables    => [ '%osconsts' ]
 );

my  $osconsts;
our %osconsts;

BEGIN {
    $osconsts = osconsts_table;
    push @constants, keys %$osconsts;
    tie %osconsts, 'POSIX::1003::ReadOnlyTable', $osconsts;
}

=chapter NAME

POSIX::1003::OS - POSIX for the file-system

=chapter SYNOPSIS

  use POSIX::1003::OS qw(uname TMP_MAX);
  my ($sys, $node, $rel, $version, $machine) = uname();
  print TMP_MAX;

=chapter DESCRIPTION
You may also need M<POSIX::1003::Pathconf>.

=chapter FUNCTIONS

=function uname 

Get the name of current operating system.

 my ($sysname, $node, $release, $version, $machine) = uname();

Note that the actual meanings of the various fields are not
that well standardized: do not expect any great portability.
The C<$sysname> might be the name of the operating system, the
C<$nodename> might be the name of the host, the C<$release> might be
the (major) release number of the operating system, the
C<$version> might be the (minor) release number of the operating
system, and C<$machine> might be a hardware identifier.
Maybe.

=chapter CONSTANTS

Be warned that constants defined in this module may move to mode
specific modules over time.

=for comment
#TABLE_OS_START

The constant names for this math module are inserted here during
installation.

=for comment
#TABLE_OS_END

=cut

sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $osconsts->{$name};
    sub () {$val};
}

1;
