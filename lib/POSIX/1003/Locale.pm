use warnings;
use strict;

package POSIX::1003::Locale;
use base 'POSIX::1003::Module';

# Blocks from resp. limits.h and local.h
my @constants = qw/
  MB_LEN_MAX

  LC_ALL LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERIC
  LC_TIME
 /;

my @functions = qw/localeconv setlocale/;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  );

=chapter NAME

POSIX::1003::Locale - POSIX handling locale settings

=chapter SYNOPSIS

  use POSIX::1003::Locale;

  my $location = setlocale(LC_ALL, 'de'); # German
  my $info     = localeconv();            # is HASH
  print Dumper $info;  # use Data::Dumper to inspect

=chapter DESCRIPTION
See L<perllocale> for the details.

=chapter CONSTANTS

=section Constants from limits.h
  MB_LEN_MAX   Max multi-byte length of a char across all locales

=section Constants from locale.h

  LC_ALL LC_COLLATE LC_CTYPE LC_MESSAGES LC_MONETARY LC_NUMERIC
  LC_TIME

=chapter FUNCTIONS

=function localeconv
Get detailed information about the current locale

  my $info     = localeconv();            # is HASH
  print Dumper $info;  # use Data::Dumper to inspect

=function setlocale
Locales describe national and language specific facts.  With
M<setlocale()> you change the locale.

  my $location = setlocale(LC_ALL, 'de'); # German

=cut

1;
