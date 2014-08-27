use warnings;
use strict;

package POSIX::1003::Math;
use base 'POSIX::1003::Module';

# Block respectively from float.h, math.h, stdlib.h, limits.h
my @constants = qw/
 DBL_DIG DBL_EPSILON DBL_MANT_DIG DBL_MAX DBL_MAX_10_EXP
 DBL_MAX_EXP DBL_MIN DBL_MIN_10_EXP DBL_MIN_EXP FLT_DIG FLT_EPSILON
 FLT_MANT_DIG FLT_MAX FLT_MAX_10_EXP FLT_MAX_EXP FLT_MIN FLT_MIN_10_EXP
 FLT_MIN_EXP FLT_RADIX FLT_ROUNDS LDBL_DIG LDBL_EPSILON LDBL_MANT_DIG
 LDBL_MAX LDBL_MAX_10_EXP LDBL_MAX_EXP LDBL_MIN LDBL_MIN_10_EXP
 LDBL_MIN_EXP

 HUGE_VAL

 RAND_MAX

 CHAR_BIT CHAR_MAX CHAR_MIN UCHAR_MAX SCHAR_MAX SCHAR_MIN
 SHRT_MAX SHRT_MIN USHRT_MAX
 INT_MAX INT_MIN UINT_MAX
 LONG_MAX LONG_MIN ULONG_MAX
 /;

# Only from math.h.  The first block are defined in POSIX.xs, the
# second block present in Core. The last is from string.h
our @IN_CORE = qw/abs exp log sqrt sin cos atan2 rand srand int/;

my @functions = qw/
 acos asin atan ceil cosh floor fmod frexp
 ldexp log10 modf sinh tan tanh

 div rint pow
 strtod strtol strtoul
/;
push @functions, @IN_CORE;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  );

=chapter NAME

POSIX::1003::Math - POSIX handling time

=chapter SYNOPSIS

  use POSIX::1003::Math qw/ceil floor sqrt/;
  print ceil 3.14;
  print sqrt floor 4.9;

=chapter DESCRIPTION

B<Be aware> that math in Perl has unclear precission! Be aware that the
math library often provides many variations of these functions... it is
hard to determine which one is used. Probably, M<Math::Trig> will serve
you better. Or M<PDL> for real number crunchers.

B<Be warned> that these functions do not have an obligatory scalar
parameter, but only an optional parameter (defaults to C<$_>). This
means that they have the lowest (is list) priority.

=chapter FUNCTIONS

=section Standard POSIX via this module (via POSIX.xs)
Like the built-in sin, cos, and sqrt, the EXPR defaults to C<$_> and
there is a scalar context (missing from POSIX.pm).

=function acos $expr
=function asin $expr
=function atan $expr
=function ceil $expr
=function cosh $expr
=function floor $expr
=function frexp $expr
=function ldexp $expr
=function log10 $expr
=function sinh $expr
=function tan $expr
=function tanh $expr
=cut

# the argument to be optional is important for expression priority!
sub acos(_)  { goto &POSIX::acos  }
sub asin(_)  { goto &POSIX::asin  }
sub atan(_)  { goto &POSIX::atan  }
sub ceil(_)  { goto &POSIX::ceil  }
sub cosh(_)  { goto &POSIX::cosh  }
sub floor(_) { goto &POSIX::floor }
sub frexp(_) { goto &POSIX::frexp }
sub ldexp(_) { goto &POSIX::ldexp }
sub log10(_) { goto &POSIX::log10 }
sub sinh(_)  { goto &POSIX::sinh  }
sub tan(_)   { goto &POSIX::tan   }
sub tanh(_)  { goto &POSIX::tanh  }

=function modf $expr, $expr
=function fmod $expr, $expr
=cut
sub modf($$) { goto &POSIX::modf }
sub fmod($$) { goto &POSIX::fmod }

# All provided by POSIX.xs

=function div $numer, $denominator
Devide $numer by $denominator. The result is a list of two: quotient and
remainder.  Implemented in Perl for completeness, currently not with the
speed of XS.

  my ($quotient, $remainder) = div($number, $denom);
=cut

sub div($$) { ( int($_[0]/$_[1]), ($_[0] % $_[1]) ) }

=function rint $number
Round to the closest integer.  Implemented in Perl for completeness.
=cut

sub rint(;$) { my $v = @_ ? shift : $_; int($v + 0.5) }

=function pow $expr1, $expr2
Returns C<$expr1 ** $expr2>
=cut

sub pow($$) { $_[0] ** $_[1] }

=section Standard POSIX, using CORE
A small set of mathematical functions are available in Perl CORE,
without the need to load this module.  But if you do import them,
it simply gets ignored.

=function abs [$expr]
=function exp [$expr]
=function log [$expr]
=function sqrt [$expr]
=function sin [$expr]
=function cos [$expr]
=function atan2 $expr, $expr
=function srand [$expr]
=function rand [$expr]
=cut

#------------------------------
=section Numeric conversions

All C<strto*>, C<atof>, C<atoi> and friends functions are usually
not needed in Perl programs: the integer and float types are at their
largest size, so when a string is used in numeric context it will get
converted automatically.  Still, POSIX.xs does provide a few of those
functions, which are sometimes more accurate in number parsing for
large numbers.

All three provided functions treat errors the same way.  Truly
POSIX-compliant systems set C<$ERRNO> ($!) to indicate a translation
error, so clear C<$!> before calling strto*.  Non-compliant systems
may not check for overflow, and therefore will never set C<$!>.

To parse a string C<$str> as a floating point number use

  $! = 0;
  ($num, $n_unparsed) = strtod($str);

  if($str eq '' || $n_unparsed != 0 || $!) {
      die "Non-numeric input $str" . ($! ? ": $!\n" : "\n");
  }

  # When you do not care about handling errors, you can do
  $num = strtod($str);
  $num = $str + 0;     # same: Perl auto-converts

=function strtod STRING
String to double translation.  Returns the parsed number and the number
of characters in the unparsed portion of the string.  When called in a
scalar context C<strtod> returns the parsed number.

=function strtol STRING, $base
String to integer translation.  Returns the parsed number and
the number of characters in the unparsed portion of the string.
When called in a scalar context C<strtol> returns the parsed number.

The base should be zero or between 2 and 36, inclusive.  When the base
is zero or omitted C<strtol> will use the string itself to determine the
base: a leading "0x" or "0X" means hexadecimal; a leading "0" means
octal; any other leading characters mean decimal.  Thus, "1234" is
parsed as a decimal number, "01234" as an octal number, and "0x1234"
as a hexadecimal number.

=function strtoul STRING, $base
String to unsigned integer translation, which behaves like C<strtol>.
=cut

=chapter CONSTANTS

The following constants are exported, shown here with the values
discovered during installation of this module:

=for comment
#TABLE_MATH_START

The constant names for this math module are inserted here during
installation.

=for comment
#TABLE_MATH_END

=cut

1;
