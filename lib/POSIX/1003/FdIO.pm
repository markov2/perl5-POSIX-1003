use warnings;
use strict;

package POSIX::1003::FdIO;
use base 'POSIX::1003';

use Fcntl qw/O_WRONLY O_CREAT O_TRUNC SEEK_CUR/;
use POSIX::1003::Pathconf qw/_PC_REC_INCR_XFER_SIZE/;

# Blocks resp from unistd.h, limits.h, and stdio.h
my @constants = qw/
 STDERR_FILENO STDIN_FILENO STDOUT_FILENO

 PIPE_BUF STREAM_MAX MAX_INPUT SSIZE_MAX

 BUFSIZ EOF
 /;

my @functions = qw/closefd creatfd dupfd dup2fd openfd pipefd
 readfd seekfd writefd

 tellfd readfd_all writefd_all 
 /;

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 );

__PACKAGE__->import(qw/SSIZE_MAX BUFSIZ/);

=chapter NAME

POSIX::1003::FdIO - POSIX handling file descriptors

=chapter SYNOPSIS

  use POSIX::1003::FdIO;
  $fd = openfd($fn, O_RDWR);
  $fd = openfd($fn, O_WRONLY|O_TRUNC);
  $fd = openfd($fn, O_CREAT|O_WRONLY, 0640);

  my $buf;
  $bytes_read    = readfd($fd, $buf, BUFSIZ);
  $bytes_written = writefd($fd, $buf, 5);

  $off_t = seekfd($fd, 0, SEEK_SET);  # rewind!
  $fd2   = dupfd($fd);

  closefd($fd) or die $!;

  my ($r, $w) = pipefd();
  writefd($w, "hello", 5);
  readfd($r, $buf, 5);
  closefd($r) && closefd($w) or die $!;

=chapter DESCRIPTION
Most people believe that the C<sys*> commands in Perl-Core are not
capable of doing unbuffered IO. For those people, we have this module.

=chapter CONSTANTS

=section Constants from unistd.h
 #name             #fixed value
 STDIN_FILENO      0
 STDOUT_FILENO     1
 STDERR_FILENO     2
=cut

use constant
 { STDIN_FILENO  => 0
 , STDOUT_FILENO => 1
 , STDERR_FILENO => 2
 };

=section Constants from limits.h
 PIPE_BUF
 STREAM_MAX == _POSIX_STREAM_MAX
            Minimum nr of streams supported by POSIX compliant
            systems
 MAX_INPUT  Size of the type-ahead buffer (terminal)
 SSIZE_MAX  Max bytes taken in a single read or write system call

=section Constants from stdio.h
There is no C<POSIX::1003::Stdio> (yet), but these values may
also be useful in non-buffered IO.
 BUFSIZ     Common IO buffer size
 EOF        End of file

=chapter FUNCTIONS

=section Overview

Perl defaults to use file-handles avoiding file descriptors. For
that reason, the C<fread> of POSIX is the C<read> of Perl; that's
confusing. The POSIX-in-Core implementation makes you write
C<CORE::read()> and C<POSIX::read()> explicitly. However,
C<POSIX::read()> is the same as C<CORE::sysread()>!

For all people who do not trust the C<sys*> commands (and there are
many), we provide the implementation of POSIX-in-Core with a less
confusing name to avoid accidents.

 POSIX   Perl-Core POSIX.pm POSIX::1003::FdIO
 fseek   seek
 lseek   sysseek   lseek    seekfd
 fopen   open
 open    sysopen            openfd  # sysopen clumpsy
 fdopen                             # IO::Handle->new_from_fd
 fclose  close
 close   close     close    closefd
 fread   read
 read    sysread   read     readfd
 fwrite  write
 write   syswrite  write    writefd
 pipe              pipe     pipefd
         pipe,open                  # buffered unless $|=0
 creat             creat    creatfd
 dup                        dupfd
 stat    stat
 fstat             fstat    statfd
 lstat   lstat
 ftell   tell
                            tellfd  # tell on fd not in POSIX

=section Standard POSIX

=function seekfd FD, OFFSET, WHENCE
The WHENCE is a C<SEEK_*> constant from M<Fcntl>

=function openfd FILENAME, FLAGS, MODE
Returned is an integer file descriptor (FD). FLAGS are composed
from the C<O_*> constants defined by M<Fcntl> (import tag C<:mode>)
The MODE combines C<S_I*> constants from that same module.

=function closefd FD
Always check the return code: C<undef> on error, cause in C<$!>.
  closefd $fd or die $!;

There is no C<sysclose()> in core, because C<sysopen()> does unbuffered
IO via its perl-style file-handle: when you open with C<CORE::sysopen()>,
you must close with C<CORE::close()>.

=function readfd FD, SCALAR, [LENGTH]
Read the maximum of LENGTH bytes from FD into the SCALAR. Returned is
the actual number of bytes read.

=function writefd FD, BYTES, [LENGTH]
Attempt to write the first LENGTH bytes of STRING to FD. Returned is
the number of bytes actually written. The number of bytes written
can be less than LENGTH without an error condition: you have to call
write again with the remaining bytes. You have an error only when C<-1>
is returned.

=function dupfd FD
Copy the file-descriptor FD into the lowest-numbered unused descriptor.
The new fd is returned, undef on failure.

=function dup2fd FD, NEWFD
Copy file-descriptor FD to an explicit NEWFD number. When already
in use, the file at NEWFD will be closed first.  Returns undef on
failure.

=function pipefd
Returns the reader and writer file descriptors.
  my ($r, $w) = pipefd;
  writefd($w, "hello", 5 );
  readfd($r, $buf, 5 );

=function statfd FD

=function creatfd FILENAME, MODE
Implemented via M<openfd()>, which is true by definition of POSIX.
=cut

sub seekfd($$$)   { goto &POSIX::lseek }
sub openfd($$;$)  { goto &POSIX::open  }
sub closefd($)    { goto &POSIX::close }
sub readfd($$;$)  { push @_, SSIZE_MAX()  if @_==2; goto &POSIX::read  }
sub writefd($$;$) { push @_, length $_[1] if @_==2; goto &POSIX::write }
sub pipefd()      { goto &POSIX::pipe  }
sub dupfd($)      { goto &POSIX::dup   }
sub dup2fd($$)    { goto &POSIX::dup2  }
sub statfd($)     { goto &POSIX::fstat }
sub creatfd($$)   { openfd $_[0], O_WRONLY|O_CREAT|O_TRUNC, $_[1] }

=section Additional
Zillions of Perl programs reimplement these functions. Let's simplify
code.

=function tellfd FD
Reports the location in the file.
=cut

sub tellfd($) {seekfd $_[0], 0, SEEK_CUR() }

=function writefd_all FD, BYTES, [DO_CLOSE]
Be sure that BYTES have the utf-8 flag off! We are working with bytes
here, not strings.  Returns false if something went wrong (error in C<$!>)
The FD will get closed when DO_CLOSE is provided and true.

=example
  my $out = creatfd $outfile, 0600;
  writefd_all $out, $bytes, 1
      or die "write to $outfile failed: $!\n";
=cut

sub writefd_all($$;$)
{   my ($to, $data, $do_close) = @_;

    while(my $l = length $data)
    {   my $written = writefd $to, $data, $l;
        return undef if $written==-1;
        last if $l eq $written;    # normal case
        substr($data, 0, $written) = '';
    }

    $do_close or return 1;
    closefd $to != -1;
}

=function readfd_all FD, [SIZE, [DO_CLOSE]]
Read all remaining bytes from the FD.  At most SIZE bytes are read,
which defaults to SSIZE_MAX.

The maximum SIZE would be SSIZE_MAX, but POSIX.xs pre-allocs a buffer
with that size, so 2^64 is too large. We will read in convenient

  my $in = openfd $filename, O_RDONLY;
  my $d  = readfd_all $in, undef, 1;
  defined $d or die "cannot read from $filename: $!\n";

=cut

sub readfd_all($;$$)
{   my ($in, $size, $do_close) = @_;
    defined $size or $size = SSIZE_MAX();
    my ($data, $buf) = ('', '');

    my $block = _PC_REC_INCR_XFER_SIZE($in) || BUFSIZ() || 4096;
    while(my $bytes = readfd $in, $buf, ($block < $size ? $block : $size))
    {   if($bytes==-1)    # read-error, will also show in $! of closefd
        {   undef $data;
            last;
        }
        last if $bytes==0;
        $data .= $buf;
        $size -= $bytes;
    }

    $do_close or return $data;
    closefd($in) ? $data : undef;
}

1;
