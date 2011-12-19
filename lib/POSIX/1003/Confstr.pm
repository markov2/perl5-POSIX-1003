use warnings;
use strict;

package POSIX::1003::Confstr;
use base 'POSIX::1003';

use Carp 'croak';

my @constants;
my @functions = qw/confstr confstr_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , table     => [ '%confstr' ]
  );

my  $confstr;
our %confstr;

BEGIN {
    # initialize the :constants export tag
    $confstr = confstr_table;
    push @constants, keys %$confstr;
    tie %confstr, 'POSIX::1003::ReadOnlyTable', $confstr;
}

=chapter NAME

POSIX::1003::Confstr - POSIX access to confstr()

=chapter SYNOPSIS

  use POSIX::1003::Confstr;   # import all

  use POSIX::1003::Confstr 'confstr';
  my $path = confstr('_CS_PATH');

  use POSIX::1003::Confstr '_CS_PATH';
  my $path = _CS_PATH;

  use POSIX::1003::Confstr '%confstr';
  my $key = $confstr{_CS_PATH};
  $confstr{_CS_NEW_CONF} = $key;

=chapter DESCRIPTION

=chapter FUNCTIONS

=section Standard POSIX

=function confstr NAME
Returns the confstr value related to the NAMEd constant.  The NAME
must be a string. C<undef> will be returned when the NAME is not
known by the system.
=example
  my $path = confstr('_CS_PATH') || '/bin:/usr/bin';
=cut

sub confstr($)
{   my $key = shift // return;
    $key =~ /^_CS_/
        or croak "pass the constant name as string";

    my $id  = $confstr->{$key} // return;
    _confstr($id);
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $id = $confstr->{$name} // return sub() {undef};
    sub() {_confstr($id)};
}

=section Additional

=function confstr_names
Returns a list with all known names, unsorted.
=cut

sub confstr_names() { keys %$confstr }

=chapter CONSTANTS
The exported variable C<%confstr> is a HASH which maps C<_CS_*> names
on unique numbers, to be used with the system's C<confstr()> function.
=cut

1;
