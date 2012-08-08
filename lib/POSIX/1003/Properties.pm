use warnings;
use strict;

package POSIX::1003::Properties;
use base 'POSIX::1003::Module';

use Carp 'croak';

my @constants;
my @functions = qw/property property_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%property' ]
  );

my  $property;
our %property;

BEGIN {
    # initialize the :constants export tag
    $property = property_table;
    push @constants, keys %$property;
    tie %property, 'POSIX::1003::ReadOnlyTable', $property;
}

sub property($);

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
When you compile C/C++ programs, the header files provide you with
a long list of C<_POSIX> constants. This module pass these values
on to Perl.

=chapter METHODS
=cut

sub exampleValue($)
{   my ($class, $name) = @_;
    $name =~ m/^_POSIX/ or return;
    my $val = property $name;
    defined $val ? $val : 'undef';
}

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
    $key =~ /^_POSIX/
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

=over 4
=item B<%property>
This exported variable is a tie HASH which contains the
values related to the system property names.
=back

The following constants where detected on your system when the
module got installed.  The second column shows the value which
where returned at that time.

=for comment
#TABLE_PROPERTY_START

   If you install the module, the table will be filled-in here

=for comment
#TABLE_PROPERTY_END

=cut

1;
