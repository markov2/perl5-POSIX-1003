use warnings;
use strict;

package POSIX::1003::Time;
use base 'POSIX::1003::Module';

use POSIX::1003::Locale  qw(setlocale LC_TIME);
use Encode               qw(find_encoding is_utf8 decode);

our @IN_CORE  = qw/gmtime localtime/;

my @constants;
my @functions = qw/
  asctime ctime strftime
  clock difftime mktime
  tzset tzname/;
push @functions, @IN_CORE;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  , tables    => [ '%time' ]
  );

my  $time;
our %time;

BEGIN {
    $time = time_table;
    push @constants, keys %$time;
    tie %time, 'POSIX::1003::ReadOnlyTable', $time;
}

=chapter NAME

POSIX::1003::Time - POSIX handling time

=chapter SYNOPSIS

  use POSIX::1003::Time;

  tzset();      # set-up local timezone from $ENV{TZ}
  ($std, $dst) = tzname;  # timezone abbreviations

  $str = ctime($timestamp);   # is equivalent to:
  $str = asctime(localtime($timestamp))

  $str = strftime("%A, %B %d, %Y", 0, 0, 0, 12, 11, 95, 2);
  # $str contains "Tuesday, December 12, 1995"

  $timestamp = mktime(0, 30, 10, 12, 11, 95);
  print "Date = ", ctime($timestamp);

  print scalar localtime;
  my $year   = (localtime)[5] + 1900;

  $timespan  = difftime($end, $begin);

=chapter DESCRIPTION

=chapter FUNCTIONS

=section Standard POSIX

B<Warning:> the functions M<asctime()>, M<mktime()>, and M<strftime()>
share a weird complex encoding with M<localtime()> and M<gmtime()>:
the month (C<mon>), weekday (C<wday>), and yearday (C<yday>) begin at
zero.  I.e. January is 0, not 1; Sunday is 0, not 1; January 1st is 0,
not 1.  The year (C<year>) is given in years since 1900.  I.e., the year
1995 is 95; the year 2001 is 101.

=function asctime $sec, $min, $hour, $mday, $mon, $year, ...
The C<asctime> function uses C<strftime> with a fixed format, to produce
timestamps with a trailing new-line.  Example:

  "Sun Sep 16 01:03:52 1973\n"

The parameter order is the same as for M<strftime()> without its C<$format>
parameter:

  my $str = asctime($sec, $min, $hour, $mday, $mon, $year,
                 $wday, $yday, $isdst);

=function clock 
The amount of spent processor time in microseconds.

=function ctime $timestamp

  # equivalent
  my $str = ctime $timestamp;
  my $str = asctime localtime $timestamp;

=function difftime $timestamp, $timestamp
Difference between two TIMESTAMPs, which are floats.

  $timespan = difftime($end, $begin);

=function mktime $sec, $min, $hour, $mday, $mon, $year, ...
Convert date/time info to a calendar time.
Returns "undef" on failure.

   my $t = mktime(sec, min, hour, mday, mon, year,
              wday = 0, yday = 0, isdst = -1)

  # Calendar time for December 12, 1995, at 10:30 am
  $timestamp = mktime(0, 30, 10, 12, 11, 95);
  print "Date = ", ctime($time_t);

=function strftime $format, $sec, $min, $hour, $mday, $mon, $year, ...
The formatting of C<strftime> is extremely flexible but the parameters
are quite tricky.  Read carefully!

  my $str = strftime($fmt, $sec, $min, $hour,
      $mday, $mon, $year, $wday, $yday, $isdst);

If you want your code to be portable, your $format argument
should use only the conversion specifiers defined by the ANSI C
standard (C89, to play safe).  These are C<aAbBcdHIjmMpSUwWxXyYZ%>.
But even then, the results of some of the conversion specifiers are
non-portable.

[0.95_5] This implementation of C<strftime()> is character-set aware,
even when the LC_TIME table does not match the type of the format string.
=cut

sub strftime($@)
{   my $fmt = shift;

#XXX See https://github.com/abeltje/lc_time for the correct implementation,
#    using nl_langinfo(CODESET)

    my $lc  = setlocale LC_TIME;
    if($lc && $lc =~ m/\.([\w-]+)/ && (my $enc = find_encoding $1))
    {   # enforce the format string (may contain any text) to the same
        # charset as the locale is using.
        my $rawfmt = $enc->encode($fmt);
        return $enc->decode(POSIX::strftime($rawfmt, @_));
    }

    if(is_utf8($fmt))
    {   # no charset in locale, hence ascii inserts
        my $out = POSIX::strftime(encode($fmt, 'utf8'), @_);
        return decode $out, 'utf8';
    }

    # don't know about the charset
    POSIX::strftime($fmt, @_);
}

=function tzset 
Set-up local timezone from C<$ENV{TZ}> and the OS.

=function tzname 
Returns the strings to be used to represent Standard time (STD)
respectively Daylight Savings Time (DST).

  tzset();
  my ($std, $dst) = tzname;
=cut

# Everything in POSIX.xs

=function gmtime [$time]
Simply L<perlfunc/gmtime>

=function localtime [$time]
Simply L<perlfunc/localtime>

=chapter CONSTANTS

=for comment
#TABLE_TIME_START

The constant names for this module are inserted here during
installation.

=for comment
#TABLE_TIME_END

=cut

sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $time->{$name};
    sub () {$val};
}

1;
