use warnings;
use strict;

package POSIX::1003::Pathconf;
use base 'POSIX::1003::Module';

use Carp 'croak';

my @constants;
my @functions = qw/pathconf fpathconf pathconf_names/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%pathconf' ]
  );

my  $pathconf;
our %pathconf;

BEGIN {
    # initialize the :constants export tag
    $pathconf = pathconf_table;
    push @constants, keys %$pathconf;
    tie %pathconf, 'POSIX::1003::ReadOnlyTable', $pathconf;
}

sub pathconf($$);

=chapter NAME

POSIX::1003::Pathconf - POSIX access to pathconf()

=chapter SYNOPSIS

  use POSIX::1003::Pathconf;   # import all

  use POSIX::1003::Pathconf 'pathconf';
  my $max    = pathconf($filename, '_PC_PATH_MAX');

  use POSIX::1003::Pathconf '_PC_PATH_MAX';
  my $max    = _PC_PATH_MAX($filename);

  use POSIX::1003::Pathconf qw(pathconf %pathconf);
  my $key    = $pathconf{_PC_PATH_MAX};
  $pathconf{_PC_NEW_KEY} = $value
  foreach my $name (keys %pathconf) ...

  use POSIX::1003::Pathconf qw(fpathconf);
  use POSIX::1003::FdIO     qw(openfd);
  use Fcntl                 qw(O_RDONLY);
  my $fd     = openfd $fn, O_RDONLY;
  my $max    = fpathconf $fd, '_PC_PATH_MAX';
  my $max    = _PC_PATH_MAX($fd);

  foreach my $pc (pathconf_names) ...

=chapter DESCRIPTION
With C<pathconf()> you query filesystem limits for a certain existing
location.

=chapter METHODS
=cut

sub exampleValue($)
{   my ($class, $name) = @_;
    $name =~ m/^_PC_/ or return;
    my $val = pathconf __FILE__, $name;
    defined $val ? $val : 'undef';
}

=chapter FUNCTIONS

=section Standard POSIX
=function fpathconf $fd, $name
Returns the numeric value related to the $name or C<undef>.

=function pathconf $filename, $name
Returns the numeric value related to the $name or C<undef>.
=cut

sub fpathconf($$)
{   my ($fd, $key) = @_;
    $key =~ /^_PC_/
        or croak "pass the constant name as string";
    my $id = $pathconf{$key} // return;
    my $v  = POSIX::fpathconf($fd, $id);
    defined $v && $v eq '0 but true' ? 0 : $v;
}

sub pathconf($$)
{   my ($fn, $key) = @_;
    $key =~ /^_PC_/
        or croak "pass the constant name as string";
    my $id = $pathconf{$key} // return;
    my $v = POSIX::pathconf($fn, $id);
    defined $v ? $v+0 : undef;  # remove 'but true' from '0'
}

sub _create_constant($)
{   my ($class, $name) = @_;
    my $id = $pathconf->{$name} // return sub($) {undef};
    sub($) { my $f = shift;
               $f =~ m/\D/
             ? POSIX::pathconf($f, $id)
             : POSIX::fpathconf($f, $id)
           };
}

=section Additional

=function pathconf_names 
Returns a list with all known names, unsorted.
=cut

sub pathconf_names() { keys %$pathconf }

=chapter CONSTANTS

=over 4
=item B<%pathconf>
This exported variable is a tied HASH which maps C<_PC_*> names
on unique numbers, to be used with the system's C<pathconf()>
and C<fpathconf()> functions.

The following constants where detected on your system when the
module got installed.  The second column shows the value which
where returned for a random file at the time.
=back

=for comment
#TABLE_PATHCONF_START

   If you install the module, the table will be filled-in here

=for comment
#TABLE_PATHCONF_END

=cut
