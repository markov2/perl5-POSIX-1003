#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <unistd.h>

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

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Sysconf

HV *
sysconf_table()
    CODE:
	RETVAL = fill_sysconf();
    OUTPUT:
	RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Confstr

HV *
confstr_table()
    CODE:
	RETVAL = fill_confstr();
    OUTPUT:
	RETVAL

SV *
_confstr(name)
	int		name;
    PREINIT:
	char 		buf[4096];
	STRLEN		len;
    CODE:
	len = confstr(name, buf, sizeof(buf));
	RETVAL = len==0 ? &PL_sv_undef : newSVpv(buf, len-1);
    OUTPUT:
	RETVAL


MODULE = POSIX::1003	PACKAGE = POSIX::1003::Pathconf

HV *
pathconf_table()
    CODE:
	RETVAL = fill_pathconf();
    OUTPUT:
	RETVAL

MODULE = POSIX::1003	PACKAGE = POSIX::1003::Properties

HV *
property_table()
    CODE:
	RETVAL = fill_properties();
    OUTPUT:
	RETVAL
