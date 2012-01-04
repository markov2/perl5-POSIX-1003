use warnings;
use strict;

package POSIX::3;

use Carp qw/croak/;

my %own_functions = map +($_ => 1), qw/
  posix_1003_modules
  posix_1003_names
  show_posix_names
 /;

our (%EXPORT_TAGS, %IMPORT_FROM);

=chapter NAME

POSIX::3 - help POSIX::1003 modules

=chapter SYNOPSIS
  use POSIX::3 qw(:termios :pc PATH_MAX);
  # is short for
  use POSIX::1003::Termios  qw(:all);
  use POSIX::1003::Pathconf qw(:all);
  use POSIX::1003::FS       qw(PATH_MAX);

  # overview about all exported symbols (by a module)
  show_posix_names 'POSIX::1003::Pathconf';
  show_posix_names ':pc';
  perl -MPOSIX::3 'show_posix_names'

=chapter DESCRIPTION
The M<POSIX::1003> suite implements access to many POSIX functions. It
can be quite some work to type-in all the explicit C<require> lines. This
module is slower during the import (because it knows the location of each
of the hundreds of symbols) but loads the right modules automatically.

=section Exporter
This module uses nasty export tricks, so is not based in M<Exporter>.
Some modules have more than one tag related to them, and one tag may
load multiple modules. When you do not specify symbol or tag, then B<all>
are loaded into your namespace(!), the same behavior as M<POSIX> has.

If your import list starts with C<+1>, the symbols will not get into
your own namespace, but that of your caller. Just like
C<$Exporter::ExportLevel> (but a simpler syntax).

  use POSIX::3 ':pathconf';
  use POSIX::3 ':pc';       # same, abbreviated name

  use POSIX::3 qw(PATH_MAX :math sin);

  sub MyModule::import(@)   # your own tricky exporter
  {   POSIX::3->import('+1', @_);
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
  , props =>       'POSIX::1003::Properties'
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

{   eval "require POSIX::3::Symbols";
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
    foreach (sort keys %order)
    {   my $name = $order{$_};
        my $pkg  = $pkg_of->{$name};
        (my $abbrev = $pkg) =~ s/^POSIX\:\:1003\:\:/P::3::/;
        printf "%-16s :%-10s %s\n", $abbrev, $mod_tag{$pkg}, $name;
    }
    print "*** ".(keys %$pkg_of)." symbols in total\n";
}

1;
