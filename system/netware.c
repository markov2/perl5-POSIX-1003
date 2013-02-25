/*
 * NetWare OS
 */

#ifdef HAS_POLL
#undef HAS_POLL
#endif

#ifdef HAS_ULIMIT
#undef HAS_ULIMIT
#endif

/* defines makedev(),major(),minor() */
#include <sys/sysmacros.h>
