use ExtUtils::MakeMaker;

# The system.c file must sometimes exist to avoid errors in 'make', eventhough
# the real file will get generated as first thing when make runs.
open TOUCH, '>', 'system.c' and close TOUCH;

WriteMakefile
  ( NAME        => 'POSIX::1003'
  , VERSION_FROM => 'lib/POSIX/1003/Module.pm'
  , PREREQ_PM   =>
     { Test::More     => 0.47
     , POSIX          => 0
     , XSLoader       => 0
     , File::Spec     => 0
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'POSIX::1003, alternative for POSIX in core'
  , LICENSE     => 'perl'
  , PL_FILES    => {}
  , INC         => '-I.'
  , realclean   => {FILES => '*.c'}
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

config:: system.c
	$(NOECHO) $(ECHO) "*** autodetect available symbols"
	$(FULLPERL) lists.PL

linkext:: $(MAN3PODS)
	$(NOECHO) $(ECHO) "*** collect all defined symbols"
	$(FULLPERL) symbols.PL
	$(NOECHO) $(ECHO) "*** adding values examples to manuals"
	$(FULLPERL) manuals.PL $(MAN3PODS)

# for DIST
RAWDIR          = ../public_html/posix/raw
DISTDIR         = ../public_html/posix/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2011
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net
__POSTAMBLE

