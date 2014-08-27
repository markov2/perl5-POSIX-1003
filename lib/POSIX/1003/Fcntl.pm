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

our @IN_CORE  = qw/
fcntl
flock/;

my $fcntl;
our %fcntl;

BEGIN {
    $fcntl = fcntl_table;
    push @constants, keys %$fcntl;
    tie %fcntl,  'POSIX::1003::ReadOnlyTable', $fcntl;
}

use constant UNUSED => 0;

# We need to have these values, but get into a chicked-egg problem with
# the normal import() procedure.
use constant
 { F_DUPFD      => $fcntl->{F_DUPFD}
 , F_DUPFD_CLOEXEC => $fcntl->{F_DUPFD_CLOEXEC}
 , F_GETFD      => $fcntl->{F_GETFD}
 , F_GETFL      => $fcntl->{F_GETFL}
 , F_GETLCK     => $fcntl->{F_GETLCK}
 , F_GETLEASE   => $fcntl->{F_GETLEASE}
 , F_GETLK      => $fcntl->{F_GETLK}
 , F_GETLKW     => $fcntl->{F_GETLKW}
 , F_GETOWN     => $fcntl->{F_GETOWN}
 , F_GETOWN_EX  => $fcntl->{F_GETOWN_EX}
 , F_GETPIPE_SZ => $fcntl->{F_GETPIPE_SZ}
 , F_GETSIG     => $fcntl->{F_GETSIG}
 , F_NOTIFY     => $fcntl->{F_NOTIFY}
 , F_OWNER_PGRP => $fcntl->{F_OWNER_PGRP}
 , F_OWNER_PID  => $fcntl->{F_OWNER_PID}
 , F_RDLCK      => $fcntl->{F_RDLCK}
 , F_SETFD      => $fcntl->{F_SETFD}
 , F_SETFL      => $fcntl->{F_SETFL}
 , F_SETLEASE   => $fcntl->{F_SETLEASE}
 , F_SETLK      => $fcntl->{F_SETLK}
 , F_SETLKW     => $fcntl->{F_SETLKW}
 , F_SETOWN     => $fcntl->{F_SETOWN}
 , F_SETOWN_EX  => $fcntl->{F_SETOWN_EX}
 , F_SETPIPE_SZ => $fcntl->{F_SETPIPE_SZ}
 , F_SETSIG     => $fcntl->{F_SETSIG}
 , F_UNLCK      => $fcntl->{F_UNLCK}
 , F_WRLCK      => $fcntl->{F_WRLCK}
 };

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
  if(lockf $fd, F_LOCK) ...
  lockf $fd, F_ULOCK;
=cut

sub lockf($$;$)
{   my ($file, $flags, $len) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _lockf($fd, $flags, $len//0);
}

=section Additional

=function fcntl_dup $fd|$fh, %options

Functions F_DUPFD and F_DUPFD_CLOEXEC: dupplicate a file-descriptor
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
    my $func = $args{close_on_exec} ? F_DUPFD_CLOEXEC : F_DUPFD;

    return _fcntl $fd, F_DUPFD, UNUSED
        if !$args{close_on_exec};

    return _fcntl $fd, F_DUPFD_CLOEXEC, UNUSED
        if defined F_DUPFD_CLOEXEC;

    _fcntl $fd, F_DUPFD, UNUSED;
    setfd_control $fd, O_CLOEXEC;
}

=function getfd_control $fd|$fh
Control the file descriptor flags, function F_GETFD.
=cut

sub getfd_control($)
{   my ($file) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_GETFD, UNUSED;
}

=function setfd_control $fd|$fh, $flags
Change the file descriptor flags, function F_SETFD.
=cut

sub setfd_control($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETFD, $flags;
}

=function getfd_flags $fd|$fh
Get the file status flags and access modes, function F_GETFL.

=example
  my $flags = getfd_flags(fd);
  if ((flags & O_ACCMODE) == O_RDWR)
=cut

sub getfd_flags($)
{   my ($file) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_GETFL, UNUSED;
}

=function setfd_flags $fd|$fh, $flags
Change the file status flags and access modes, function F_SETFL.
=cut

sub setfd_flags($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETFL, $flags;
}

=function setfd_lock $fd|$fh, %options

Functions F_SETLK and F_SETLKW: request a lock for (a section of) a file.

=option  type  F_RDLCK|F_WRLCK|F_UNLCK
=default type  F_RDLCK

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
  setfd_lock \*IN, type => F_WRLCK, wait => 1
      or die "cannot lock IN: $!\n";
=cut

sub setfd_lock($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;

    my $func;
    $func   = $args{wait} ? F_SETLKP : F_SETLKWP if $args{private};
    $func ||= $args{wait} ? F_SETLK  : F_SETLKW;

    $args{type}   //= F_RDLCK;
    $args{whence} //= SEEK_SET;
    $args{start}  //= 0;
    $args{len}    //= 0;
    _lock $fd, $func, \%args;
}

=function getfd_islocked $fd|$fh, %options

Function F_GETLCK. Returns the first lock which would prevent getting
the lock.  The %options are the same as for M<setfd_lock()>.

=example
  if(my $lock = getfd_islocked \*IN) ...
=cut

sub getfd_islocked($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    $args{type}   //= F_RDLCK;
    $args{whence} //= SEEK_SET;
    $args{start}  //= 0;
    $args{len}    //= 0;

    my $func = $args{private} ? (F_GETLKW//F_GETLK) : F_GETLK;
    my $lock = _lock $fd, $func, \%args
       or return undef;

    #XXX MO: how to represent "ENOSYS"?
    $lock->{type}==F_UNLCK ? undef : $lock;
}

=function getfd_owner $fd|$fh, %options
Function F_GETOWN or F_GETOWN_EX.

=examples
  my ($type, $pid) = getfd_owner($fd);
  defined $type or die $!;
  if($type==F_OWNER_PGRP) ...

  my $pid = getfd_owner($fd) or die $!;
=cut

sub getfd_owner($%)
{   my ($file, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;

    my ($type, $pid) = _own_ex $fd, F_GETOWN_EX, UNUSED, UNUSED;
    unless(defined $type && $!==ENOSYS)
    {   $pid = _fcntl $fd, F_GETOWN, UNUSED;
        if($pid < 0)
        {   $pid  = -$pid;
            $type = F_OWNER_PGRP // 2;
        }
        else
        {   $type = F_OWNER_PID  // 1;
        }
    }

    wantarray ? ($type, $pid) : $pid;
}

=function setfd_owner $fd|$fh, $pid, %options

Function F_GETOWN or F_GETOWN_EX.  The _EX version is attempted
if provided.

=option  type F_OWNER_TID|F_OWNER_PID|F_OWNER_PGRP
=default type <looks at sign>

=examples
  setfd_owner($fh, $pid) or die $!;
  setfd_owner($fh, $pid, type => F_OWNER_TID) or die $!;
  setfd_owner($fh, -9);  # $pid=9, type=F_OWNER_PGRP

=cut

sub setfd_owner($$%)
{   my ($file, $pid, %args) = @_;
    my $fd   = ref $file ? fileno($file) : $file;

    my $type = $args{type}
            || ($pid < 0 ? (F_OWNER_PGRP//2) : (F_OWNER_PID//1));

    $pid     = -$pid if $pid < 0;

    my ($t, $p) = _own_ex $fd, F_SETOWN_EX, $pid, $type;
    unless($t && $!==ENOSYS)
    {   my $sig_pid = $type==(F_OWNER_PGRP//2) ? -$pid : $pid;
        ($t, $p) = _fcntl $fd, F_SETOWN, $pid;
    }

    defined $t;
}

=function setfd_signal $fd|$fh, $signal
Function F_SETSIG.

=examples
 setfd_signal(\*STDOUT, SIGINT) or die $!;
=cut

sub setfd_signal($$)
{   my ($file, $signal) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETSIG, $signal;
}

=function getfd_signal $fd|$fh
Function F_GETSIG.

=examples
 my $signal = getfd_signal(\*STDOUT) or die $!;
=cut

sub getfd_signal($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETSIG, UNUSED;
}

=function setfd_lease $fd|$fh, $flags
Function F_SETLEASE.

=examples
 setfd_lease(\*STDOUT, F_WRLCK) or die $!;
=cut

sub setfd_lease($$)
{   my ($file, $flags) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETLEASE, $flags;
}

=function getfd_lease $fd|$fh
Function F_GETLEASE.

=examples
 my $lease = getfd_lease(\*STDIN) or die $!;
 if($lease != F_RDLCK) ...
=cut

sub getfd_lease($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_GETLEASE, UNUSED;
}


=function setfd_notify $fd|$fh, $flags
Function F_NOTIFY.

=example
  my $d = openfd('/etc', O_RDONLY|O_DIRECTORY) or die $!;
  setfd_notify($d, DN_ACCESS|DN_CREATE|DN_MULTISHOT) or die $!;
  
=cut

sub setfd_notify($$)
{   my ($dir, $flags) = @_;
    my $fd   = ref $dir ? fileno($dir) : $dir;
    _fcntl $fd, F_NOTIFY, $flags;
}

=function setfd_pipe_size $fd|$fh, $size
Function F_SETPIPE_SZ.

=examples
 setfd_pipe_size($pipe, 16384) or die $!;
=cut

sub setfd_pipe_size($$)
{   my ($file, $size) = @_;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_SETPIPE_SZ, $size;
}

=function getfd_pipe_size $fd|$fh
Function F_GETPIPE_SZ.

=examples
 my $size = getfd_pipe_size($pipe) or die $!;
=cut

sub getfd_pipe_size($)
{   my $file = shift;
    my $fd   = ref $file ? fileno($file) : $file;
    _fcntl $fd, F_GETPIPE_SZ, UNUSED;
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
