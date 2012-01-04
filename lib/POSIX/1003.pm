use strict;
use warnings;

package POSIX::1003;

our $VERSION = '0.10';
use Carp 'croak';

{ use XSLoader;
  XSLoader::load 'POSIX';
  XSLoader::load 'POSIX::1003', $VERSION;
}

my $constant_table = qr/ ^ (?:
   _SC_      # sysconf
 | _CS_      # confstr
 | _PC_      # pathconf
 | _POSIX_   # property
 | UL_       # ulimit
 | RLIM      # rlimit
 | GET_|SET_ # rlimit aix
 | POLL      # poll
 | SIG       # signals
 ) /x;

sub import(@)
{   my $class = shift;
    return if $class eq __PACKAGE__;

    no strict 'refs';
    no warnings 'once';

    my $tags = \%{"${class}::EXPORT_TAGS"} or die;

    # A hash-lookup is faster than an array lookup, so %EXPORT_OK
    %{"${class}::EXPORT_OK"} = ();
    my $ok   = \%{"${class}::EXPORT_OK"};
    unless(keys %$ok)
    {   @{$ok}{@{$tags->{$_}}} = () for keys %$tags;
    }

    my $level = @_ && $_[0] =~ m/^\+(\d+)$/ ? shift : 0;
    return if @_==1 && $_[0] eq ':none';
    @_ = ':all' if !@_;

    my %take;
    foreach (@_)
    {   if( $_ eq ':all')
        {   @take{keys %$ok} = ();
        }
        elsif( m/^:(.*)/ )
        {   my $tag = $tags->{$1} or croak "$class does not export $_";
            @take{@$tag} = ();
        }
        else
        {   $_ =~ $constant_table or exists $ok->{$_}
               or croak "$class does not export $_";
            undef $take{$_};
        }
    }

    my $in_core = \@{$class.'::IN_CORE'} || [];

    my $pkg = (caller $level)[0];
    foreach my $f (sort keys %take)
    {   my $export;
        if(exists ${$class.'::'}{$f} && ($export = *{"${class}::$f"}{CODE}))
        {   # reuse the already created function; might also be a function
            # which is actually implemented in the $class namespace.
        }
        elsif($f =~ $constant_table)
        {   *{$class.'::'.$f} = $export = $class->_create_constant($f);
        }
        elsif( $f !~ m/[^A-Z0-9_]/ )  # faster than: $f =~ m!^[A-Z0-9_]+$!
        {   # other all-caps names are always from POSIX.xs
            if(exists $POSIX::{$f} && defined *{"POSIX::$f"}{CODE})
            {   # POSIX.xs croaks on undefined constants, we will return undef
                my $const = eval "POSIX::$f()";
                *{$class.'::'.$f} = $export
                  = defined $const ? sub() {$const} : sub() {undef};
            }
            else
            {   # ignore the missing value
#               warn "missing constant in POSIX.pm $f" && next;
                *{$class.'::'.$f} = $export = sub() {undef};
            }
        }
        elsif(exists $POSIX::{$f} && defined *{"POSIX::$f"}{CODE})
        {   # normal functions implemented in POSIX.xs
            *{"${class}::$f"} = $export = *{"POSIX::$f"}{CODE};
        }
        elsif($f =~ s/^%//)
        {   $export = \%{"${class}::$f"};
        }
        elsif($in_core && grep {$f eq $_} @$in_core)
        {   # function is in core, simply ignore the export
            next;
        }
        else
        {   croak "unable to load $f";
        }

        no warnings 'once';
        *{"${pkg}::$f"} = $export;
    }
}

=chapter NAME
POSIX::1003 - POSIX 1003.1 extensions to Perl

=chapter SYNOPSIS
   # use the specific extensions
   # and see POSIX::Overview and POSIX::3

=chapter DESCRIPTION
The M<POSIX> module in I<core> (distributed with Perl itself) is ancient,
the documentation is usually wrong, and it has too much unusable code in it.
C<POSIX::1003> tries to provide cleaner access to the operating
system.  More about the choices made can be found in section L</Rationale>,

The official POSIX standard is large, with over 1200 functions;
M<POSIX::Overview> does list them all. This collection of C<POSIX::1003>
extension provides access to quite a number of those functions, when they
are not provided by "core". They also define as many system constants
as possible. More functions may get added in the future.

B<Start looking in POSIX::Overview>, to discover which module
provides certain functionality. You may also guess the location from
the module names listed in L</DETAILS>, below.

=section Exporter
All modules provide a C<:constants> and a C<:functions> tag, sometimes
more.  The default is C<:all>, which means: everthing. You may also
specify C<:none> (of course: nothing).

When the import list is preceeded by C<+1>, the symbols will get published
into the namespace of the caller namespace.

  use POSIX::1003::Pathconf;
  use POSIX::1003::Pathconf ':all';  # same
  use POSIX::3 ':pc';                # same, for the lazy
  use POSIX::3 ':pathconf';          # same, less lazy

  sub MyModule::import(@)   # your own tricky exporter
  {   POSIX::1003::Pathconf->import('+1', @_);
  }

=chapter DETAILS

=section Modules in this distribution

=over 4
=item M<POSIX::1003::Confstr>
Provide access to the C<_CS_*> constants.
=item M<POSIX::1003::FdIO>
Provides unbuffered IO handling; based on file-descriptors.
=item M<POSIX::1003::FS>
Some generic file-system information. See also M<POSIX::1003::Pathconf>
for more precise info.
=item M<POSIX::1003::Locale>
Locales, see also L<perllocale>.
=item M<POSIX::1003::Math>
Standard math functions of unknown precission.
=item M<POSIX::1003::OS>
A few ways to get Operating system information.
See also M<POSIX::1003::Sysconf>, M<POSIX::1003::Confstr>, and
M<POSIX::1003::Properties>,
=item M<POSIX::1003::Pathconf>
Provide access to the C<pathconf()> and its trillion C<_PC_*> constants.
=item M<POSIX::1003::Properties>
Provide access to the C<_POSIX_*> constants.
=item M<POSIX::1003::Signals>
With helper modules M<POSIX::SigSet> and M<POSIX::SigAction>.
=item M<POSIX::1003::Sysconf>
Provide access to the C<sysconf> and its zillion C<_SC_*> constants.
=item M<POSIX::1003::Termios>
Terminal IO
=item M<POSIX::1003::Time>
Time-stamp processing
=item M<POSIX::1003::Limit>
For getting and setting resource limits.
=back

=section Other modules
=over 4
=item M<Fcntl>
Flags for modes, seek and fcntl are left to be defined by
the M<Fcntl> module.
=item M<Errno>
All constants representing error numbers are left to be defined in
the M<Errno> module.
=item M<User::pwent>
Provides an OO interface around C<getpw*()>
=item M<User::grent>
Provides an OO interface around C<getgr*()>
=item M<Unix::SavedIDs>
provides access to all C<(get|set)e?[ug]id> functions. Of
course, you may use the special variables C<< $( $) $< $> >> as well,
but that gives unpredictable results.
=back

=section Rationale

The POSIX module as distributed with Perl itself is ancient (it dates
before Perl5)  Although it proclaims that it provides access to all
POSIX functions, it only lists about 200 out of 1200. From that subset,
half of the functions with croak when you use them, complaining that
they cannot get implemented in Perl for some reason.

Many other functions provided by POSIX-in-Core simply forward the caller
to a function with the same name which is in basic perl (see perldoc).
With a few serious complications: the functions in POSIX do not use
prototypes, sometimes expect different arguments and sometimes return
different values.

Back to the basics: the M<POSIX::1003> provides access to the POSIX
libraries where they can be made compatible with Perl's way of doing
things. For instance, C<setuid> of POSIX is implemented with C<$)>,
whose exact behavior depends on compile-flags and OS: it's not the pure
C<setuid()> of the standard hence left-out. There is no C<isalpha()>
either: not compatible with Perl strings and implemented very different
interface from POSIX. And there is also no own C<exit()>, because we have
a C<CORE::exit()> with the same functionality.

=section POSIX::1003 compared to POSIX

This distribution does not add much functionality itself: it is
mainly core's POSIX.xs (which is always available and ported to
all platforms). You can access these routines via M<POSIX> as
well.

When you are used to POSIX.pm but want to move to M<POSIX::1003>,
you must be aware about the following differences:

=over 4
=item *
the constants and functions are spread over many separate modules,
based on their purpose, where M<POSIX> uses a header filename as
tag to group provided functionality.

=item *
functions provided by CORE are usually not exported again by
POSIX::1003 (unless to avoid confusion, for instance: is
C<atan2()> in core or ::Math?)

=item *
constants which are already provided via M<Fcntl> or M<Errno> are
not provided by this module as well. This should reduce the chance
for confusion.

=item *
functions which are also in CORE can be imported, but will silently
be ignored. In C<POSIX>, functions with the same name get exported
without prototype, which does have consequences for interpretation of
your program.  This module uses prototypes on all exported functions,
like CORE does.

=item *
hundreds of C<_SC_*>, C<_CS_*>, C<_PC_*>, C<_POSIX_*>, C<UL_*>,
and C<RLIMIT_*> constants were collected from various sources, not just
a minimal subset. You get access to all defined on your system.

=item *
when an user program addresses a constant which is not defined by the
system, POSIX will croak. Modules in POSIX::1003 on the other hand,
will return C<undef>.

This simplifies code like this:

  use POSIX::1003::FS         'PATH_MAX';
  use POSIX::1003::PathConfig '_PC_PATH_MAX';
  my $max_fn = _PC_PATH_MAX($fn) // PATH_MAX // 1024;

With the tranditional POSIX, you have to C<eval()> each use
of a constant.

=back
=cut

package POSIX::1003::ReadOnlyTable;
sub TIEHASH($) { bless $_[1], $_[0] }
sub FETCH($)   { $_[0]->{$_[1]} }
sub EXISTS($)  { exists $_[0]->{$_[1]} }
sub FIRSTKEY() { scalar %{$_[0]}; scalar each %{$_[0]} }
sub NEXTKEY()  { scalar each %{$_[0]} }

1;
