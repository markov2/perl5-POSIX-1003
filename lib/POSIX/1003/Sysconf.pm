# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Sysconf;
use base 'POSIX::1003::Module';

use warnings;
use strict;

use Carp    'croak';

my @constants;
my @functions = qw/sysconf sysconf_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%sysconf' ]
  );

my  $sysconf;
our %sysconf;

BEGIN {
    $sysconf = sysconf_table;
    push @constants, keys %$sysconf;
    tie %sysconf, 'POSIX::1003::ReadOnlyTable', $sysconf;
}

sub sysconf($);

=chapter NAME

POSIX::1003::Sysconf - POSIX access to sysconf()

=chapter SYNOPSIS

  use POSIX::1003::Sysconf; # load all names

  use POSIX::1003::Sysconf qw(sysconf);
  # keys are strings!
  $ticks = sysconf('_SC_CLK_TCK');

  use POSIX::1003::Sysconf qw(sysconf _SC_CLK_TCK);
  $ticks  = _SC_CLK_TCK;   # constants are subs

  use POSIX::1003::Sysconf '%sysconf';
  my $key = $sysconf{_SC_CLK_TCK};
  $sysconf{_SC_NEW_KEY} = $key_code;
  $ticks  = sysconf($key);

  print "$_\n" for keys %sysconf;

=chapter DESCRIPTION
The C<sysconf()> interface can be used to query system information
in numerical form, where C<confstr()> returns strings.

=chapter METHODS
=cut

sub exampleValue($)
{   my ($class, $name) = @_;
    $name =~ m/^_SC_/ or return;
    my $val = sysconf $name;
    defined $val ? $val : 'undef';
}

=chapter FUNCTIONS

=section Standard POSIX

=function sysconf $name
Returns the sysconf value related to the NAMEd constant.  The $name
must be a string. C<undef> will be returned when the $name is not
known by the system.
=example
  my $ticks = sysconf('_SC_CLK_TCK') || 1000;
=cut

sub sysconf($)
{   my $key = shift // return;
    $key =~ /^_SC_/
        or croak "pass the constant name as string";
 
    my $id  = $sysconf->{$key}    // return;
    my $val = POSIX::sysconf($id) // return;
    $val+0;        # remove " but true" from "0"
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $id = $sysconf->{$name} // return sub() {undef};
    sub() {POSIX::sysconf($id)};
}

=section Additional

=function sysconf_names 
Returns a list with all known names, unsorted.
=cut

sub sysconf_names() { keys %$sysconf }

=chapter CONSTANTS

=over 4
=item B<%sysconf>
This exported variable is a tied HASH which maps C<_SC_*> names
on unique numbers, to be used with the system's C<sysconf()> function.
=back

The following constants where detected on your system when the
module got installed.  The second column shows the value which
where returned at that time.

=for comment
#TABLE_SYSCONF_START

  During installation, a symbol table will get inserted here.


=for comment
#TABLE_SYSCONF_END

=cut

1;
