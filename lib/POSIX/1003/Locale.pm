# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Locale;
use base 'POSIX::1003::Module';

use warnings;
use strict;

# Blocks from resp. limits.h and local.h
my @constants;
my @functions = qw/localeconv setlocale/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%locale' ]
  );

my  $locale;
our %locale;

BEGIN {
    $locale = locale_table;
    push @constants, keys %$locale;
    tie %locale, 'POSIX::1003::ReadOnlyTable', $locale;
}

=chapter NAME

POSIX::1003::Locale - POSIX handling locale settings

=chapter SYNOPSIS

  use POSIX::1003::Locale;

  my $location = setlocale(LC_ALL, 'de'); # German
  my $info     = localeconv();            # is HASH
  print Dumper $info;  # use Data::Dumper to inspect

=chapter DESCRIPTION
See L<perllocale> for the details.

=chapter FUNCTIONS

=function localeconv 
Get detailed information about the current locale

  my $info     = localeconv();            # is HASH
  print Dumper $info;  # use Data::Dumper to inspect

=function setlocale $lc, $lang
Locales describe national and language specific facts.  With
M<setlocale()> you change the locale.

  my $location = setlocale(LC_ALL, 'de'); # German

=chapter CONSTANTS

=for comment
#TABLE_LOCALE_START

  During installation, a symbol table will get inserted here.

=for comment
#TABLE_LOCALE_END

=cut

sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $locale->{$name};
    sub () {$val};
}


1;
