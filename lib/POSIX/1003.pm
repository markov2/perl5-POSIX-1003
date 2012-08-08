use warnings;
use strict;

package POSIX::1003;

use Carp qw/croak/;

my %own_functions = map +($_ => 1), qw/
  posix_1003_modules
  posix_1003_names
  show_posix_names
 /;

our (%EXPORT_TAGS, %IMPORT_FROM);

=chapter NAME

POSIX::1003 - bulk-load POSIX::1003 symbols

=chapter SYNOPSIS
  use POSIX::1003  qw(:termios :pc PATH_MAX);
  # is short for all of these:
  use POSIX::1003::Termios  qw(:all);
  use POSIX::1003::Pathconf qw(:all);
  use POSIX::1003::FS       qw(PATH_MAX);

  # overview about all exported symbols (by a module)
  show_posix_names 'POSIX::1003::Pathconf';
  show_posix_names ':pc';
  perl -MPOSIX::1003 'show_posix_names'

=chapter DESCRIPTION

The M<POSIX::1003> suite implements access to many POSIX functions. The
M<POSIX> module in I<core> (distributed with Perl itself) is ancient, the
documentation is usually wrong, and it has too much unusable code in it.
C<POSIX::1003> tries to provide cleaner access to the operating system.
More about the choices made can be found in section L</Rationale>.

=section POSIX
The official POSIX standard is large, with over 1200 functions;
M<POSIX::Overview> does list them all. This collection of C<POSIX::1003>
extension provides access to quite a number of those functions, when they
are not provided by "core". They also define as many system constants
as possible. More functions may get added in the future.

B<Start looking in POSIX::Overview>, to discover which module
provides certain functionality. You may also guess the location from
the module names listed in L</DETAILS>, below.

=section Bulk loading
It can be quite some work to work-out which modules define what symbols
and then write down all the explicit C<require> lines. Using bulk loading
via this C<POSIX::1003> will be slower during the import (because it needs
to load the location of each of the hundreds of symbols into memory),
but provides convenience: it loads the right modules automagically.

=subsection Exporter
This module uses nasty export tricks, so is not based in M<Exporter>.
Some modules have more than one tag related to them, and one tag may
load multiple modules. When you do not specify symbol or tag, then B<all>
are loaded into your namespace(!), the same behavior as M<POSIX> has.

If your import list starts with C<+1>, the symbols will not get into
your own namespace, but that of your caller. Just like
C<$Exporter::ExportLevel> (but a simpler syntax).

  use POSIX::1003 ':pathconf';
  use POSIX::1003 ':pc';       # same, abbreviated name

  use POSIX::1003 qw(PATH_MAX :math sin);

  sub MyModule::import(@)   # your own tricky exporter
  {   POSIX::1003->import('+1', @_);
  }

=subsection EXPORT_TAGS

  :all                  (all symbols, default)
  :cs      :confstr     POSIX::1003::Confstr
  :ev      :events      POSIX::1003::Events
  :fd      :fdio        POSIX::1003::FdIO
  :fs      :filesystem  POSIX::1003::FS
  :limit   :limits      POSIX::1003::Limit
  :locale               POSIX::1003::Locale
  :math                 POSIX::1003::Math
  :none                 (nothing)
  :os      :opsys       POSIX::1003::OS
  :pc      :pathconf    POSIX::1003::Pathconf
  :proc    :processes   POSIX::1003::Proc
  :props   :properties  POSIX::1003::Properties
  :posix   :property    POSIX::1003::Properties
  :sc      :sysconf     POSIX::1003::Sysconf
  :signals              POSIX::1003::Signals
  :signals :sigaction   POSIX::SigAction
  :signals :sigset      POSIX::SigSet
  :termio  :termios     POSIX::1003::Termios
  :time                 POSIX::1003::Time

=chapter FUNCTIONS

=cut

my %tags =
  ( confstr =>     'POSIX::1003::Confstr'
  , cs =>          'POSIX::1003::Confstr'
  , events =>      'POSIX::1003::Events'
  , ev =>          'POSIX::1003::Events'
  , fdio =>        'POSIX::1003::FdIO'
  , fd =>          'POSIX::1003::FdIO'
  , filesystem =>  'POSIX::1003::FS'
  , fs =>          'POSIX::1003::FS'
  , limit =>       'POSIX::1003::Limit'
  , limits =>      'POSIX::1003::Limit'
  , locale =>      'POSIX::1003::Locale'
  , math =>        'POSIX::1003::Math'
  , os =>          'POSIX::1003::OS'
  , opsys =>       'POSIX::1003::OS'
  , pathconf =>    'POSIX::1003::Pathconf'
  , pc =>          'POSIX::1003::Pathconf'
  , processes =>   'POSIX::1003::Proc'
  , proc =>        'POSIX::1003::Proc'
  , properties =>  'POSIX::1003::Properties'
  , property =>    'POSIX::1003::Properties'
  , props =>       'POSIX::1003::Properties'
  , posix =>       'POSIX::1003::Properties'
  , sc =>          'POSIX::1003::Sysconf'
  , sigaction =>   'POSIX::SigAction'
  , signals =>     [qw/POSIX::1003::Signals POSIX::SigSet POSIX::SigAction/]
  , sigset =>      'POSIX::SigSet'
  , sysconf =>     'POSIX::1003::Sysconf'
  , termio =>      'POSIX::1003::Termios'
  , termios =>     'POSIX::1003::Termios'
  , time =>        'POSIX::1003::Time'
  );

my %mod_tag;
while(my ($tag, $pkg) = each %tags)
{   $pkg = $pkg->[0] if ref $pkg eq 'ARRAY';
    $mod_tag{$pkg} = $tag
        if !$mod_tag{$pkg}
        || length $mod_tag{$pkg} < length $tag;
}

{   eval "require POSIX::1003::Symbols";
    die $@ if $@;
}

while(my ($pkg, $tag) = each %mod_tag)  # unique modules
{   $IMPORT_FROM{$_} = $tag for @{$EXPORT_TAGS{$tag}};
}

sub _tag2mods($)
{   my $tag = shift;
    my $r   = $tags{$tag} or croak "unknown tag '$tag'";
    ref $r eq 'ARRAY' ? @$r : $r;
}

sub _mod2tag($) { $mod_tag{$_[0]} }
sub _tags()     { keys %tags}

sub import(@)
{   my $class = shift;
    my (%mods, %from);

    my $level = @_ && $_[0] =~ /^\+(\d+)$/ ? shift : 0;
    return if @_==1 && $_[0] eq ':none';
    @_ = ':all' if !@_;

    no strict 'refs';
    no warnings 'once';
    my $to    = (caller $level)[0];

    foreach (@_)
    {   if($_ eq ':all')
        {   $mods{$_}++ for values %mod_tag;
            *{$to.'::'.$_} = \&$_ for keys %own_functions;
        }
        elsif(m/^\:(.*)/)
        {   exists $tags{$1} or croak "unknown tag '$_'";
            $mods{$_}++ for map $mod_tag{$_}, _tag2mods $1;  # remove aliases
        }
        elsif($own_functions{$_})
        {   *{$to.'::'.$_} = \&$_;
        }
        else
        {   my $mod = $IMPORT_FROM{$_} or croak "unknown symbol '$_'";
            push @{$from{$mod}}, $_;
        }
    }

    # no need for separate symbols when we need all
    delete $from{$_} for keys %mods;

#   print "from $_ all\n"          for keys %mods;
#   print "from $_ @{$from{$_}}\n" for keys %from;

    my $up = '+' . ($level+1);
    foreach my $tag (keys %mods)     # whole tags
    {   foreach my $pkg (_tag2mods($tag))
        {   eval "require $pkg"; die $@ if $@;
            $pkg->import($up, ':all');
        }
    }
    foreach my $tag (keys %from)     # separate symbols
    {   foreach my $pkg (_tag2mods($tag))
        {   eval "require $pkg"; die $@ if $@;
            $pkg->import($up, @{$from{$tag}});
        }
   }
}

=function posix_1003_modules
Returns the names of all modules in the current release of POSIX::1003.
=cut

sub posix_1003_modules()
{   my %mods;
    foreach my $mods (values %tags)
    {   $mods{$_}++ for ref $mods eq 'ARRAY' ? @$mods : $mods;
    }
    keys %mods;
}

=function posix_1003_names [MODULES|TAGS]
Returns  all the names, when in LIST content.  In SCALAR context,
it returns (a reference to) an HASH which contains exported names
to modules mappings.  If no explicit MODULES are specified, then all
available modules are taken.
=cut

sub posix_1003_names(@)
{   my %names;
    my @modules;
    if(@_)
    {   my %mods;
        foreach my $sel (@_)
        {   $mods{$_}++ for $sel =~ m/^:(\w+)/ ? _tag2mods($1) : $sel;
        }
        @modules = keys %mods;
    }
    else
    {   @modules = posix_1003_modules;
    }

    foreach my $pkg (@modules)
    {   eval "require $pkg";
        $@ && next;  # die?
        $pkg->can('import') or next;
        $pkg->import(':none');   # create %EXPORT_OK

        no strict 'refs';
        my $exports = \%{"${pkg}::EXPORT_OK"};
        $names{$_} = $pkg for keys %$exports;
    }

    wantarray ? keys %names : \%names;
}

=function show_posix_names [MODULES|TAGS]
Print all names defined by the POSIX::1003 suite in alphabetical
(case-insensitive) order. If no explicit MODULES are specified, then all
available modules are taken.
=cut

sub show_posix_names(@)
{   my $pkg_of = posix_1003_names @_;
    my %order  = map {(my $n = lc $_) =~ s/[^A-Za-z0-9]//g; ($n => $_)}
        keys %$pkg_of;  # Swartzian transform

    no strict 'refs';
    foreach (sort keys %order)
    {   my $name = $order{$_};
        my $pkg  = $pkg_of->{$name};
        $pkg->import($name);
        my $val  = $pkg->exampleValue($name);
        (my $abbrev = $pkg) =~ s/^POSIX\:\:1003\:\:/::/;
        my $mod  = $mod_tag{$pkg};
        if(defined $val)
        {   printf "%-12s :%-10s %-30s %s\n", $abbrev, $mod, $name, $val;
        }
        else
        {   printf "%-12s :%-10s %s\n", $abbrev, $mod, $name;
        }
    }
    print "*** ".(keys %$pkg_of)." symbols in total\n";
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

1;
