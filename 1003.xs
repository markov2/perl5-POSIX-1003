#define PERL_EXT_POSIX_1003

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <unistd.h>

#ifndef HAS_CONFSTR
#define HAS_CONFSTR
#endif

#ifndef HAS_ULIMIT
#define HAS_ULIMIT
#endif

#ifndef HAS_RLIMIT
#define HAS_RLIMIT
#endif

#ifndef HAS_MKNOD
#define HAS_MKNOD
#endif

#ifdef HAS_RLIMIT
#ifdef __USE_FILE_OFFSET64
#define HAS_RLIMIT_64
#endif
#endif

/*
 * work-arounds for various operating systems
 */

#include "system.c"

#ifdef HAS_ULIMIT
#include <ulimit.h>
#endif

#ifdef HAS_RLIMIT
#include <sys/resource.h>
#endif

HV * sc_table = NULL;
HV *
fill_sysconf()
{   if(sc_table) return sc_table;

    sc_table = newHV();
#include "sysconf.c"
    return sc_table;
}

HV * cs_table = NULL;
HV *
fill_confstr()
{   if(cs_table) return cs_table;

    cs_table = newHV();
#include "confstr.c"
    return cs_table;
}

HV * pc_table = NULL;
HV *
fill_pathconf()
{   if(pc_table) return pc_table;

    pc_table = newHV();
#include "pathconf.c"
    return pc_table;
}

HV * pr_table = NULL;
HV *
fill_properties()
{   if(pr_table) return pr_table;

    pr_table = newHV();
#include "properties.c"
    return pr_table;
}

HV * ul_table = NULL;
HV *
fill_ulimit()
{   if(ul_table) return ul_table;

    ul_table = newHV();
#include "ulimit.c"
    return ul_table;
}

HV * rl_table = NULL;
HV *
fill_rlimit()
{   if(rl_table) return rl_table;

    rl_table = newHV();
#include "rlimit.c"
    return rl_table;
}

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Sysconf

HV *
sysconf_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_sysconf();
    OUTPUT:
	RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Confstr

HV *
confstr_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_confstr();
    OUTPUT:
	RETVAL

SV *
_confstr(name)
	int		name;
    PROTOTYPE: $
    PREINIT:
	char 		buf[4096];
	STRLEN		len;
    CODE:
#ifdef HAS_CONFSTR
	len = confstr(name, buf, sizeof(buf));
	RETVAL = len==0 ? &PL_sv_undef : newSVpv(buf, len-1);
#else
	RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL


MODULE = POSIX::1003	PACKAGE = POSIX::1003::Pathconf

HV *
pathconf_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_pathconf();
    OUTPUT:
	RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Properties

HV *
property_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_properties();
    OUTPUT:
	RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Limit

HV *
ulimit_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_ulimit();
    OUTPUT:
	RETVAL

HV *
rlimit_table()
    PROTOTYPE:
    CODE:
	RETVAL = fill_rlimit();
    OUTPUT:
	RETVAL

SV *
_ulimit(cmd, value)
	int		cmd;
	long		value;
    PROTOTYPE: $$
    PREINIT:
	long		result;
    CODE:
#ifdef HAS_ULIMIT
	result = ulimit(cmd, value);
	RETVAL = result==-1 ? &PL_sv_undef : newSViv(result);
#else
	RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL

#ifdef HAS_RLIMIT
#ifdef HAS_RLIMIT_64

void
_getrlimit(resource)
	int		resource;
    PROTOTYPE: $
    PREINIT:
	struct rlimit64	rlim;
	int		result;
    PPCODE:
	/* on linux, rlim64_t is a __UQUAD_TYPE */
	result = getrlimit64(resource, &rlim);
	PUSHs(sv_2mortal(newSVuv(rlim.rlim_cur)));
	PUSHs(sv_2mortal(newSVuv(rlim.rlim_max)));
	PUSHs(result==-1 ? &PL_sv_no : &PL_sv_yes);

SV *
_setrlimit(resource, cur, max)
	int		resource;
	unsigned long   cur;
	unsigned long	max;
    PROTOTYPE: $$$
    PREINIT:
	struct rlimit64	rlim;
	int		result;
    CODE:
	rlim.rlim_cur = cur;
	rlim.rlim_max = max;
	result = setrlimit64(resource, &rlim);
	RETVAL = result==-1 ? &PL_sv_no : &PL_sv_yes;
    OUTPUT:
	RETVAL

#else /* HAS_RLIMIT_64 */


void
_getrlimit(resource)
	int		resource;
    PROTOTYPE: $
    PREINIT:
	struct rlimit	rlim;
	int		result;
    PPCODE:
	/* on linux, rlim64_t is a __ULONGWORD_TYPE */
	result = getrlimit(resource, &rlim);
	PUSHs(sv_2mortal(newSVuv(rlim.rlim_cur)));
	PUSHs(sv_2mortal(newSVuv(rlim.rlim_max)));
	PUSHs(result==-1 ? &PL_sv_no : &PL_sv_yes);

SV *
_setrlimit(resource, cur, max)
	int		resource;
	unsigned long   cur;
	unsigned long	max;
    PROTOTYPE: $$$
    PREINIT:
	struct rlimit	rlim;
	int		result;
    CODE:
	rlim.rlim_cur = cur;
	rlim.rlim_max = max;
	result = setrlimit(resource, &rlim);
	RETVAL = result==-1 ? &PL_sv_no : &PL_sv_yes;
    OUTPUT:
	RETVAL

#endif /* HAS_RLIMIT_64 */
#else  /* HAS_RLIMIT */

void
_getrlimit(resource)
	int		resource;
    PROTOTYPE: $
    PPCODE:
	PUSHs(&PL_sv_undef);
	PUSHs(&PL_sv_undef);
	PUSHs(&PL_sv_no);

SV *
_setrlimit(resource, cur, max)
	int		resource;
	unsigned long   cur;
	unsigned long	max;
    PROTOTYPE: $$$
    CODE:
	RETVAL = &PL_sv_no;
    OUTPUT:
	RETVAL

#endif /* HAS_RLIMIT */


MODULE = POSIX::1003	PACKAGE = POSIX::1003::FS

#ifdef HAS_SYSMKDEV
#include <sys/mkdev.h>
#endif

/* major, minor, and makedev usually are macro's */

dev_t
makedev(dev_t major, dev_t minor)
    PROTOTYPE: $$

dev_t
major(dev_t dev)
    PROTOTYPE: $

dev_t
minor(dev_t dev)
    PROTOTYPE: $

int
mknod(filename, mode, dev)
	char *  filename
	mode_t  mode
	dev_t   dev
    CODE:
#ifdef HAS_MKNOD
	RETVAL = mknod(filename, mode, dev);
#else
	RETVAL = &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL
