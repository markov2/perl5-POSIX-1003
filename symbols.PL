#!/usr/bin/env perl
#
# Generate tables in manual pages and for the lazy importer POSIX::1003

use POSIX::1003   qw(posix_1003_modules posix_1003_names);
use POSIX::1003::Symbols;

my $symbols = $INC{'POSIX/1003/Symbols.pm'}
   or die "cannot find filename for POSIX::1003::Symbols";

-w $symbols || chmod 0644, $symbols
   or die "cannot make $symbols readible: $!";

open SYMBOLS, '>', $symbols
    or die "cannot write to $symbols: $!";

my $now = localtime;

print SYMBOLS <<_HEAD;
# Warning: automaticall generated
#  by $0
#  at $now
# do not edit by hand!

package POSIX::1003;

our %EXPORT_TAGS = (
_HEAD

foreach my $mod (posix_1003_modules)
{   my $tag   = POSIX::1003::_mod2tag($mod);
    my $names = posix_1003_names(":$tag");
    my @names = sort {lc $a cmp lc $b} keys %$names;
    local $"  = "\n  ";
    print SYMBOLS "$tag => [ qw(\n  @names\n  ) ],\n"
}
print SYMBOLS ");\n\n# shorter aliases:\n";

my @all_tags = POSIX::1003::_tags();
foreach my $tag (sort @all_tags)
{   my $mod   = (POSIX::1003::_tag2mods($tag))[0]; 
    my $long  = POSIX::1003::_mod2tag($mod);
    print SYMBOLS "\$EXPORT_TAGS{$tag} = \$EXPORT_TAGS{$long};\n"
        if $long ne $tag;
}

print SYMBOLS <<_TAIL;

1;
_TAIL

close SYMBOLS
    or die "write errors to $symbols: $!";
