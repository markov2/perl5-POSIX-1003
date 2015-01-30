use warnings;
use strict;

package POSIX::1003::Confstr;
use base 'POSIX::1003::Module';

use Carp 'croak';

my @constants;
my @functions = qw/confstr confstr_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%confstr' ]
  );

my  $confstr;
our %confstr;
sub confstr($);

BEGIN {
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
With C<confstr()> you can retreive string values from the operating
system. It is the counterpart of C<sysconf()> which can only return
numeric values.

=chapter METHODS
=cut

sub exampleValue($)
{   my ($class, $name) = @_;
    $name =~ m/^_CS_/ or return;
    my $val = confstr $name;
    defined $val ? "'$val'" : 'undef';
}

#-----------------------
=chapter FUNCTIONS

=section Standard POSIX

=function confstr $name
Returns the confstr value related to the NAMEd constant.  The $name
must be a string. C<undef> will be returned when the $name is not
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

#--------------------------
=section Additional

=function confstr_names 
Returns a list with all known names, unsorted.
=cut

sub confstr_names() { keys %$confstr }

#--------------------------
=chapter CONSTANTS

=over 4
=item B<%confstr>
This exported variable is a (tied) HASH which maps C<_CS_*>
names to the unique numbers to be used with the system's C<confstr()>
function.
=back

The following constants where detected on your system when the
module got installed.  The second column shows the value which
where returned at that time.

=for comment
#TABLE_CONFSTR_START

  During installation, a symbol table will get inserted here.


=for comment
#TABLE_CONFSTR_END

=cut

1;
