use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME        => 'POSIX::1003'
  , VERSION_FROM => 'lib/POSIX/1003.pm'
  , PREREQ_PM   =>
     { Test::More     => 0.47
     , POSIX          => 0
     , XSLoader       => 0
     , Fcntl          => 0
     , Errno          => 0
     , File::Spec     => 0
     }
  , AUTHOR      => 'Mark Overmeer'
  , ABSTRACT    => 'POSIX::1003, alternative for POSIX in core'
  , LICENSE     => 'perl'
  , realclean   => {FILES => 'confstr.c pathconf.c properties.c sysconf.c'}
  );

#### the next lines are added for OODoc, which generates the
#### distribution.
sub MY::postamble { <<'__POSTAMBLE' }

config::
	$(FULLPERLRUNINST) gen.PL

# for DIST
RAWDIR          = ../public_html/posix/raw
DISTDIR         = ../public_html/posix/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2011
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net
__POSTAMBLE

