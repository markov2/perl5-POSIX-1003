use strict;
use warnings;

package POSIX::1003;

our $VERSION = '0.02';
use Carp 'croak';

{ use XSLoader;
  XSLoader::load 'POSIX';
  XSLoader::load 'POSIX::1003', $VERSION;
}

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

    @_ or @_ = ':all';
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
        {   m/^_(?:SC|CS|PC|POSIX)_/ || exists $ok->{$_}
                or croak "$class does not export $_";
            undef $take{$_};
        }
    }

    my $in_core = \@{$class.'::IN_CORE'} || [];

    my $pkg = caller;
    foreach my $f (sort keys %take)
    {   my $export;
        exists ${$pkg.'::'}{$f} && *{$pkg.'::'.$f}{CODE}
            and next;

        if(exists ${$class.'::'}{$f} && ($export = *{"${class}::$f"}{CODE}))
        {   # reuse the already created function; might also be a function
            # which is actually implemented in the $class namespace.
        }
        elsif( $f =~ m/^_(SC|CS|PC|POSIX)_/ )
        {   $export = $class->_create_constant($f);
        }
        elsif( $f !~ m/[^A-Z0-9_]/ )  # faster than: $f =~ m!^[A-Z0-9_]+$!
        {   # other all-caps names are always from POSIX.xs
            exists $POSIX::{$f} && defined *{"POSIX::$f"}{CODE}
                or croak "internal error: unknown POSIX constant $f";

            # POSIX.xs croaks on undefined constants, we will return undef
            my $const = eval "POSIX::$f()";
            *{$class.'::'.$f} = $export
              = defined $const ? sub {$const} : sub {undef};
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

#warn "${pkg}::$f = $export";
        no warnings 'once';
        *{"${pkg}::$f"} = $export;
    }
}

=chapter NAME
POSIX::1003 - POSIX 1003.1 extensions to Perl

=chapter SYNOPSIS
   # use the specific extensions

=chapter DESCRIPTION
The M<POSIX> module in Core (distributed with Perl itself) is ancient,
the documentation is usually wrong, and it has too much garbage in it.
The C<POSIX::1003> tries to provide cleaner access to the Operating
System.  More about the choices in section L</Rationale>,

The POSIX standard is large, over 1200 functions; M<POSIX::Overview>
does list them all. The POSIX module in Core lists a small subset. This
C<POSIX::1003> might get extended with additional functions itself.

B<Start looking> in M<POSIX::Overview>, to discover which module
provides access to certain functionality. You may also guess from
the module names, here below.

=chapter DETAILS

=section Modules in this distribution

=over 4
=item M<POSIX::1003::Confstr>
Provide access to the C<_CS_*> constants.
=item M<POSIX::1003::FdIO>
Provides unbuffered IO handling; based on file-descriptors.
=item M<POSIX::1003::FileSystem>
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
With helper modules M<POSIX::SigSet> and M<POSIX::1003::SigAction>.
=item M<POSIX::1003::Sysconf>
Provide access to the C<sysconf> and its zillion C<_SC_*> constants.
=item M<POSIX::1003::Termios>
Terminal IO
=item M<POSIX::1003::Time>
Time-stamp processing
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
=item .
the constants and functions are spread over many separate modules,
based on their purpose, where M<POSIX> uses a header filename as
tag to group provided functionality.

=item .
functions provided by CORE are usually not exported again by
POSIX::1003 (unless to avoid confusion, for instance: is
C<atan2()> in core or ::Math?)

=item .
constants which are already provided via M<Fcntl> or M<Errno> are
not provided by this module as well. This should reduce the chance
for confusion.

=item .
functions which are also in CORE can be imported, but will silently
be ignored. In C<POSIX>, functions with the same name get exported
without prototype, which does have consequences for interpretation of
your program.  This module uses prototypes on all exported functions,
like CORE does.

=item .
an attempt is made to collect all C<_SC_*>, C<_CS_*>, C<_PC_*>, and
C<_POSIX_*> constants, not just a static subset. When an user program
addresses a constant which is not defined by the system, POSIX
will croak.  Modules in POSIX::1003 on the other hand, will
return C<undef>.

This simplifies code like this:

  use POSIX::1003::FileSystem 'PATH_MAX';
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
