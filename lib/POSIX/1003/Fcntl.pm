use warnings;
use strict;

package POSIX::1003::Fcntl;
use base 'POSIX::1003::Module';

use POSIX::1003::FdIO   qw/SEEK_SET O_CLOEXEC/;
use POSIX::1003::Errno  qw/ENOSYS/;

my @constants;
my @functions = qw/fcntl
fcntl_dup
getfd_control
setfd_control
getfd_flags
setfd_flags
setfd_lock
getfd_islocked
getfd_owner
setfd_owner
setfd_signal
getfd_signal
setfd_lease
getfd_lease
setfd_notify
setfd_pipe_size
getfd_pipe_size

flock
flockfd

lockf
/;

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 , flock     => [ qw/flock flockfd LOCK_SH LOCK_EX LOCK_UN LOCK_NB/ ] 
 , lockf     => [ qw/lockf F_LOCK F_TLOCK F_ULOCK F_TEST/ ]
 , tables    => [ qw/%fcntl/ ]
 );

our @IN_CORE  = qw/fcntl flock/;

my $fcntl;

# We need to address all of our own constants via this HASH, because
# they will not be available at compile-time of this file.
our %fcntl;

BEGIN {
    $fcntl = fcntl_table;
    push @constants, keys %$fcntl;
    tie %fcntl,  'POSIX::1003::ReadOnlyTable', $fcntl;
}

# required parameter which does not get used by the OS.
use constant UNUSED => 0;

=chapter NAME

POSIX::1003::Fcntl - POSIX function fcntl

=chapter SYNOPSIS

  use POSIX::1003::Fcntl;

=chapter DESCRIPTION

One function, which hides many tricks with file-descriptors.  This module
tries to provide functions which separates the various uses.

=chapter FUNCTIONS

=section Standard POSIX

=function fcntl $fd, $function, SCALAR
See C<perlfunc fcntl>.  This raw call to C<fcntl()> is only in some
cases simple, but often isn't.

=function flockfd $fd, $flags
Not standard POSIX, but available on many POSIX platforms.  Often
implemented as M<fcntl()>, which is more complex to use.  On other
platforms implemented as separate OS feature.

Perl core provides a C<flock> which may hide plaform differences.
This C<flockfd> is the pure version.  Try to use M<setfd_lock()>, which
is more portable and flexible.

=examples
  use POSIX::1003::Fcntl ':flock';
  if(flockfd $fd, LOCK_EX|LOCK_NB) ...
  flockfd $fd, LOCK_UN;
=cut

sub flockfd($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _flock($fd, $flags);
}

=function lockf $fd, $flag, $length
Not standard POSIX, but available on many POSIX platforms.  Often
implemented via M<fcntl()>, which is more complex to use.

=examples
  use POSIX::1003::Fcntl ':lockfd';
  if(lockf $fd, $fcntl->{F_LOCK}) ...
  lockf $fd, $fcntl->{F_ULOCK};
=cut

sub lockf($$;$)
{   my ($file, $flags, $len) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _lockf($fd, $flags, $len//0);
}

=section Additional

=function fcntl_dup $fd|$fh, %options

Functions $fcntl->{F_DUPFD} and $fcntl->{F_DUPFD_CLOEXEC}: dupplicate a file-descriptor
to the lowest free fd number.

=option  close_on_exec BOOLEAN
=default close_on_exec <false>

=examples
  my $dup_fd = fcntl_dup \*STDOUT;
  my $dup_fd = fcntl_dup 2, close_on_exec => 1;

=cut

sub fcntl_dup($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    my $func = $args{close_on_exec} ? $fcntl->{F_DUPFD_CLOEXEC} : $fcntl->{F_DUPFD};

    return _fcntl $fd, $fcntl->{F_DUPFD}, UNUSED
        if !$args{close_on_exec};

    return _fcntl $fd, $fcntl->{F_DUPFD_CLOEXEC}, UNUSED
        if defined $fcntl->{F_DUPFD_CLOEXEC};

    _fcntl $fd, $fcntl->{F_DUPFD}, UNUSED;
    setfd_control $fd, O_CLOEXEC;
}

=function getfd_control $fd|$fh
Control the file descriptor flags, function $fcntl->{F_GETFD}.
=cut

sub getfd_control($)
{   my ($file) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_GETFD}, UNUSED;
}

=function setfd_control $fd|$fh, $flags
Change the file descriptor flags, function $fcntl->{F_SETFD}.
=cut

sub setfd_control($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETFD}, $flags;
}

=function getfd_flags $fd|$fh
Get the file status flags and access modes, function $fcntl->{F_GETFL}.

=example
  my $flags = getfd_flags(fd);
  if ((flags & O_ACCMODE) == O_RDWR)
=cut

sub getfd_flags($)
{   my ($file) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_GETFL}, UNUSED;
}

=function setfd_flags $fd|$fh, $flags
Change the file status flags and access modes, function $fcntl->{F_SETFL}.
=cut

sub setfd_flags($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETFL}, $flags;
}

=function setfd_lock $fd|$fh, %options

Functions $fcntl->{F_SETLK} and $fcntl->{F_SETLKW}: request a lock for (a section of) a file.

=option  type  $fcntl->{F_RDLCK}|$fcntl->{F_WRLCK}|$fcntl->{F_UNLCK}
=default type  $fcntl->{F_RDLCK}

=option  whence SEEK_SET|SEEK_CUR|SEEK_END
=default whence SEEK_SET

=option  start  FILEPOS
=default start  0

=option  len    BLOCK_LENGTH
=default len    <until end of file>

=option  wait   BOOLEAN
=default wait   <false>

=option  private BOOLEAN
=default private <false>
Linux kernel >= 3.15 provides "open file description locks", also known
as "file-private POSIX locks".  Use them when available.

=example
  setfd_lock \*IN, type => $fcntl->{F_WRLCK}, wait => 1
      or die "cannot lock IN: $!\n";
=cut

sub setfd_lock($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;

    my $func;
    $func   = $args{wait} ? $fcntl->{F_SETLKP} : $fcntl->{F_SETLKWP}
        if $args{private};

    $func //= $args{wait} ? $fcntl->{F_SETLK}  : $fcntl->{F_SETLKW};

    $args{type}   //= $fcntl->{F_RDLCK};
    $args{whence} //= SEEK_SET;
    $args{start}  //= 0;
    $args{len}    //= 0;
    _lock $fd, $func, \%args;
}

=function getfd_islocked $fd|$fh, %options

Function $fcntl->{F_GETLCK}. Returns the first lock which would prevent getting
the lock.  The %options are the same as for M<setfd_lock()>.

=example
  if(my $lock = getfd_islocked \*IN) ...
=cut

sub getfd_islocked($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    $args{type}   //= $fcntl->{F_RDLCK};
    $args{whence} //= SEEK_SET;
    $args{start}  //= 0;
    $args{len}    //= 0;

    my $func = $args{private} ? ($fcntl->{F_GETLKW}//$fcntl->{F_GETLK}) : $fcntl->{F_GETLK};
    my $lock = _lock $fd, $func, \%args
       or return undef;

    #XXX MO: how to represent "ENOSYS"?
    $lock->{type}==$fcntl->{F_UNLCK} ? undef : $lock;
}

=function getfd_owner $fd|$fh, %options
Function $fcntl->{F_GETOWN} or $fcntl->{F_GETOWN_EX}.

=examples
  my ($type, $pid) = getfd_owner($fd);
  defined $type or die $!;
  if($type==$fcntl->{F_OWNER_PGRP}) ...

  my $pid = getfd_owner($fd) or die $!;
=cut

sub getfd_owner($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;

    my ($type, $pid) = _own_ex $fd, $fcntl->{F_GETOWN_EX}, UNUSED, UNUSED;
    unless(defined $type && $!==ENOSYS)
    {   $pid = _fcntl $fd, $fcntl->{F_GETOWN}, UNUSED;
        if($pid < 0)
        {   $pid  = -$pid;
            $type = $fcntl->{F_OWNER_PGRP} // 2;
        }
        else
        {   $type = $fcntl->{F_OWNER_PID}  // 1;
        }
    }

    wantarray ? ($type, $pid) : $pid;
}

=function setfd_owner $fd|$fh, $pid, %options

Function $fcntl->{F_GETOWN} or $fcntl->{F_GETOWN_EX}.  The _EX version is attempted
if provided.

=option  type $fcntl->{F_OWNER_TID}|$fcntl->{F_OWNER_PID}|$fcntl->{F_OWNER_PGRP}
=default type <looks at sign>

=examples
  setfd_owner($fh, $pid) or die $!;
  setfd_owner($fh, $pid, type => $fcntl->{F_OWNER_TID}) or die $!;
  setfd_owner($fh, -9);  # $pid=9, type=$fcntl->{F_OWNER_PGRP}

=cut

sub setfd_owner($$%)
{   my ($file, $pid, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;

    my $type = $args{type}
            || ($pid < 0 ? ($fcntl->{F_OWNER_PGRP}//2) : ($fcntl->{F_OWNER_PID}//1));

    $pid     = -$pid if $pid < 0;

    my ($t, $p) = _own_ex $fd, $fcntl->{F_SETOWN_EX}, $pid, $type;
    unless($t && $!==ENOSYS)
    {   my $sig_pid = $type==($fcntl->{F_OWNER_PGRP}//2) ? -$pid : $pid;
        ($t, $p) = _fcntl $fd, $fcntl->{F_SETOWN}, $pid;
    }

    defined $t;
}

=function setfd_signal $fd|$fh, $signal
Function $fcntl->{F_SETSIG}.

=examples
 setfd_signal(\*STDOUT, SIGINT) or die $!;
=cut

sub setfd_signal($$)
{   my ($file, $signal) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETSIG}, $signal;
}

=function getfd_signal $fd|$fh
Function $fcntl->{F_GETSIG}.

=examples
 my $signal = getfd_signal(\*STDOUT) or die $!;
=cut

sub getfd_signal($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETSIG}, UNUSED;
}

=function setfd_lease $fd|$fh, $flags
Function $fcntl->{F_SETLEASE}.

=examples
 setfd_lease(\*STDOUT, $fcntl->{F_WRLCK}) or die $!;
=cut

sub setfd_lease($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETLEASE}, $flags;
}

=function getfd_lease $fd|$fh
Function $fcntl->{F_GETLEASE}.

=examples
 my $lease = getfd_lease(\*STDIN) or die $!;
 if($lease != $fcntl->{F_RDLCK}) ...
=cut

sub getfd_lease($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_GETLEASE}, UNUSED;
}


=function setfd_notify $fd|$fh, $flags
Function $fcntl->{F_NOTIFY}.

=example
  my $d = openfd('/etc', O_RDONLY|O_DIRECTORY) or die $!;
  setfd_notify($d, DN_ACCESS|DN_CREATE|DN_MULTISHOT) or die $!;
  
=cut

sub setfd_notify($$)
{   my ($dir, $flags) = @_;
    my $fd   = ref $dir ? fileno($dir) : $dir;
    _fcntl $fd, $fcntl->{F_NOTIFY}, $flags;
}

=function setfd_pipe_size $fd|$fh, $size
Function $fcntl->{F_SETPIPE_SZ}.

=examples
 setfd_pipe_size($pipe, 16384) or die $!;
=cut

sub setfd_pipe_size($$)
{   my ($file, $size) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_SETPIPE_SZ}, $size;
}

=function getfd_pipe_size $fd|$fh
Function $fcntl->{F_GETPIPE_SZ}.

=examples
 my $size = getfd_pipe_size($pipe) or die $!;
=cut

sub getfd_pipe_size($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, $fcntl->{F_GETPIPE_SZ}, UNUSED;
}

=chapter CONSTANTS

The following constants are exported, shown here with the values
discovered during installation of this module.

=for comment
#TABLE_FCNTL_START

The constant names for this fcntl module are inserted here during
installation.

=for comment
#TABLE_FCNTL_END

=cut

sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $fcntl->{$name};
    sub() {$val};
}

1;
