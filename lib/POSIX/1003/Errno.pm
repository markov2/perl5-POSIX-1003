use warnings;
use strict;

package POSIX::1003::Errno;
use base 'POSIX::1003::Module';

use Carp    'croak';

my @constants;
my @functions = qw/strerror errno errno_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%errno' ]
  );

my  $errno;
our %errno;

BEGIN {
    $errno = errno_table;
    push @constants, keys %$errno;
    tie %errno, 'POSIX::1003::ReadOnlyTable', $errno;
}

sub errno($);

=chapter NAME

POSIX::1003::Errno - all error codes defined by the OS

=chapter SYNOPSIS

  use POSIX::1003::Errno; # load all names

  use POSIX::1003::Errno qw(errno);
  # keys are strings!
  $ticks = errno('EPERM');

  use POSIX::1003::Errno qw(errno EPERM);
  if($!==EPERM) ...

  use POSIX::1003::Errno '%errno';
  my $key = $errno{EPERM};
  $errno{EUNKNOWN} = 1024;
  $ticks  = errno('EUNKNOWN');

  print "$_\n" for keys %errno;

=chapter DESCRIPTION
The error codes provided by your operating system.

The code modules M<Errno> and M<POSIX> do also contain an extensive
list of error numbers.  However: Errno have their values hard-coded,
which is incorrect (higher numbered codes may [do!] differ per platform).
POSIX only provides a limited subset.

=chapter METHODS
=cut

sub exampleValue($)
{   my ($class, $name) = @_;
    $name =~ m/^(?:WSA)?E/ or return;
    errno($name) // 'undef';
}

=chapter FUNCTIONS

=section Standard POSIX

=function strerror $errno
Returns the string representations of the $errno, as provided by
the operating system.
=cut

sub strerror($) { _strerror($_[0]) || "Unknown error $_[0]" }

=section Additional

=function errno $name
Returns the errno value related to the NAMEd constant.  The $name
must be a string. C<undef> will be returned when the $name is not
known by the system.
=example
  my $ticks = errno('EPERM') || 1000;
=cut

sub errno($)
{   my $key = shift // return;
    $key =~ /^(?:WSA)?E/
        or croak "pass the constant name $key as string";
 
    $errno->{$key};
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $nr = $errno->{$name} // return sub() {undef};
    sub() {$nr};
}

=function errno_names 
Returns a list with all known names, unsorted.
=cut

sub errno_names() { keys %$errno }

=chapter CONSTANTS

=over 4
=item B<%errno>
This exported variable is a tied HASH which maps C<E*> names
on numbers, to be used with the system's C<errno()> function.
=back

The following error names where detected on your system when the
module got installed.  The second column shows the related value.
Followed by the text that M<strerror()> produces for that error.

=for comment
#TABLE_ERRNO_START

  During installation, a symbol table will get inserted here.


=for comment
#TABLE_ERRNO_END

=cut

1;
