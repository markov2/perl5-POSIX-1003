use warnings;
use strict;

package POSIX::1003::Properties;
use base 'POSIX::1003';

use Carp 'croak';

my @constants;
my @functions = qw/property property_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , table     => [ '%property' ]
  );

my  $property;
our %property;

BEGIN {
    # initialize the :constants export tag
    $property = property_table;
    push @constants, keys %$property;
    tie %property, 'POSIX::1003::ReadOnlyTable', $property;
}

=chapter NAME

POSIX::1003::Properties - POSIX access to _POSIX_ constants

=chapter SYNOPSIS

  use POSIX::1003::Properties;     # import all

  use POSIX::1003::Properties 'property';
  $hasnt = property('_POSIX_NO_TRUNC');

  use POSIX::1003::Properties '_POSIX_NO_TRUNC';
  $hasnt = _POSIX_NO_TRUNC;

  use POSIX::1003::Properties '%property';
  my $key = $property{_POSIX_NO_TRUNC};
  $property{_POSIX_NEW} = $value;

  foreach my $prop (property_names) ...

=chapter DESCRIPTION

=chapter FUNCTIONS

=section Standard POSIX
There is no system call to retrieve these values: they are defined
in the C sources only.

=section Additional

=function property NAME
Returns the property value related to NAME.
=cut

sub property($)
{   my $key = shift // return;
    $key =~ /^_POSIX_/
        or croak "pass the constant name as string";

    $property->{$key};
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $value = $property->{$name};
    sub() {$value};
}

=function property_names
Returns a list with all known names, unsorted.
=cut

sub property_names() { keys %$property }

=chapter CONSTANTS
The exported variable C<%property> is a HASH which contains the
values related to the names.
=cut

1;
