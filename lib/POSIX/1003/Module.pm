use strict;
use warnings;

package POSIX::1003::Module;

# The VERSION of the distribution is sourced from this file, because
# this module also loads the XS extension.  Therefore, Makefile.PL
# extracts the version from the line below.
our $VERSION = '0.99_07';
use Carp 'croak';

# some other modules used by the program which uses POSIX::1003 may
# need POSIX.xs via POSIX.
use POSIX       ();

use XSLoader;
XSLoader::load 'POSIX::1003', $VERSION;

=chapter NAME
POSIX::1003::Module - Base of POSIX::1003 components

=chapter SYNOPSIS
   # use the specific extensions
   # and see POSIX::Overview and POSIX::1003

=chapter DESCRIPTION
The POSIX functions and constants are provided via extensions of this
module.  This module itself only facilitates those implementations.

=chapter METHODS

=method import 

All modules provide a C<:constants> and a C<:functions> tag, sometimes
more.  The default is C<:all>, which means: everthing. You may also
specify C<:none> (of course: nothing).

When the import list is preceeded by C<+1>, the symbols will get published
into the namespace of your caller namespace, not your own namespace.

  use POSIX::1003::Pathconf;
  use POSIX::1003::Pathconf ':all';  # same
  use POSIX::1003 ':pc';             # same, for the lazy
  use POSIX::1003 ':pathconf';       # same, less lazy

  sub MyModule::import(@)   # your own tricky exporter
  {   POSIX::1003::Pathconf->import('+1', @_);
  }

=cut

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
        {   is_missing($_) or exists $ok->{$_}
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
        elsif(   is_missing($f)
              || (exists $ok->{$f} && $f =~ /^[A-Z_][A-Za-z0-9_]*$/))
        {   *{$class.'::'.$f} = $export = $class->_create_constant($f);
        }
        elsif( $f !~ m/[^A-Z0-9_]/ )  # faster than: $f =~ m!^[A-Z0-9_]+$!
        {   # other all-caps names are always from POSIX.xs
#XXX MO: there should be any external names left
#warn "$f from POSIX.pm";
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
        elsif($f =~ s/^%//)
        {   $export = \%{"${class}::$f"};
        }
        elsif($in_core && grep $f eq $_, @$in_core)
        {   # function is in core, simply ignore the export
            next;
        }
        elsif(exists $POSIX::{$f} && defined *{"POSIX::$f"}{CODE})
        {   # normal functions implemented in POSIX.xs
            *{"${class}::$f"} = $export = *{"POSIX::$f"}{CODE};
        }
        else
        {   croak "unable to load $f from $class";
        }

        no warnings 'once';
        *{"${pkg}::$f"} = $export;
    }
}

=c_method exampleValue $name
Returns an example value for the NAMEd variable. Often, this is a
compile-time or runtime constant. For some extensions, like C<::Pathconf>,
that may not be the case.
=cut

sub exampleValue($)
{   my ($pkg, $name) = @_;
    no strict 'refs';

    my $tags      = \%{"$pkg\::EXPORT_TAGS"} or die;
    my $constants = $tags->{constants} || [];
    grep $_ eq $name, @$constants
        or return undef;

    my $val = $pkg->_create_constant($name)->();
    defined $val ? $val : 'undef';
}

package POSIX::1003::ReadOnlyTable;
sub TIEHASH($) { bless $_[1], $_[0] }
sub FETCH($)   { $_[0]->{$_[1]} }
sub EXISTS($)  { exists $_[0]->{$_[1]} }
sub FIRSTKEY() { scalar %{$_[0]}; scalar each %{$_[0]} }
sub NEXTKEY()  { scalar each %{$_[0]} }

1;
