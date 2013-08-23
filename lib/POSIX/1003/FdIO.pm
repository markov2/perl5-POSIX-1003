use warnings;
use strict;

package POSIX::1003::FdIO;
use base 'POSIX::1003::Module';

# Blocks resp from unistd.h, limits.h, and stdio.h
my (@constants, @seek, @mode);
my @functions = qw/closefd creatfd dupfd dup2fd openfd pipefd
  readfd seekfd writefd tellfd fdopen/;

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 , seek      => \@seek
 , mode      => \@mode
 , tables    => [ qw/%seek %mode/ ]
 );

my $fdio;
our (%fdio, %seek, %mode);

BEGIN {
    $fdio = fdio_table;
    push @constants, keys %$fdio;

    # initialize the :seek export tag
    push @seek, grep /^SEEK_/, keys %$fdio;
    my %seek_subset;
    @seek_subset{@seek} = @{$fdio}{@seek};
    tie %seek,  'POSIX::1003::ReadOnlyTable', \%seek_subset;

    # initialize the :mode export tag
    push @mode, grep /^O_/, keys %$fdio;
    my %mode_subset;
    @mode_subset{@mode} = @{$fdio}{@mode};
    tie %mode,  'POSIX::1003::ReadOnlyTable', \%mode_subset;
}

=chapter NAME

POSIX::1003::FdIO - POSIX handling file descriptors

=chapter SYNOPSIS

  use POSIX::1003::FdIO;

  $fd = openfd($fn, O_RDWR);
  defined $fd or die $!;   # $fd==0 is valid value! (STDIN)

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

  my $fh = fdopen $fd or die $!;

=chapter DESCRIPTION
Most people believe that the C<sys*> commands in Perl-Core are not
capable of doing unbuffered IO. For those people, we have this module.
The question whether C<sysread()> or M<readfd()> is meassurable faster
cannot be answered.

The C<fcntl()> command has its separate module M<POSIX::1003::Fcntl>.
Locking functions are locate there as well, because they are often
implemented via C<fcntl>.

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
 FH fseek   seek
 FD lseek   sysseek   lseek    seekfd
 FH fopen   open
 FD open    sysopen            openfd   # sysopen is clumpsy
 FD fdopen  open               fdopen   # IO::Handle->new_from_fd
 FH fclose  close
 FD close   close     close    closefd
 FH fread   read
 FD read    sysread   read     readfd
 FH fwrite  print
 FD write   syswrite  write    writefd
 FH         pipe,open                   # buffered unless $|=0
 FD pipe              pipe     pipefd
 FH stat    stat
 FD fstat             fstat    statfd
 FN lstat   lstat
 FH ftell   tell
 FD                            tellfd   # tell on fd not in POSIX
 FH rewind            rewind
 FD                            rewindfd # rewind on fd not in POSIX
 FD creat             creat    creatfd
 FD dup                        dupfd
 FD fcntl   fcntl              (many)   # see ::Fcntl
 FD flock   flock              flockfd  # see ::Fcntl
 FD lockf                      lockf    # see ::Fcntl

Works on: FH=file handle, FD=file descriptor, FN=file name

=section Standard POSIX

=function seekfd FD, OFFSET, WHENCE
The WHENCE is a C<SEEK_*> constant.

=function openfd FILENAME, FLAGS, MODE
Returned is an integer file descriptor (FD).  Returns C<undef> on
failure (and '0' is a valid FD!)

FLAGS are composed from the C<O_*> constants defined by this module (import
tag C<:mode>) The MODE field combines C<S_I*> constants defined by
M<POSIX::1003::FS> (import tag C<:stat>).

=function closefd FD
Always check the return code: C<undef> on error, cause in C<$!>.
  closefd $fd or die $!;

There is no C<sysclose()> in core, because C<sysopen()> does unbuffered
IO via its perl-style file-handle: when you open with C<CORE::sysopen()>,
you must close with C<CORE::close()>.

=function readfd FD, SCALAR, [LENGTH]
Read the maximum of LENGTH bytes from FD into the SCALAR. Returned is
the actual number of bytes read.  The value C<-1> tells you there is
an error, reported in C<$!>

B<Be warned> that a returned value smaller than LENGTH does not mean
that the FD has nothing more to offer: the end is reached only when 0
(zero) is returned.  Therefore, this reading is quite inconvenient.
You may want to use M<POSIX::Util::readfd_all()>

=function writefd FD, BYTES, [LENGTH]
Attempt to write the first LENGTH bytes of STRING to FD. Returned is
the number of bytes actually written.  You have an error only when C<-1>
is returned.

The number of bytes written can be less than LENGTH without an error
condition: you have to call write again with the remaining bytes.  This
is quite inconvenient. You may want to use M<POSIX::Util::readfd_all()>

=function dupfd FD
Copy the file-descriptor FD into the lowest-numbered unused descriptor.
The new fd is returned, undef on failure.

=function dup2fd FD, NEWFD
Copy file-descriptor FD to an explicit NEWFD number. When already
in use, the file at NEWFD will be closed first.  Returns undef on
failure.

=function pipefd
Returns the reader and writer file descriptors.
See also M<POSIX::1003::Fcntl::setfd_pipe_size()>

=example
  my ($r, $w) = pipefd;
  writefd($w, "hello", 5 );
  readfd($r, $buf, 5 );

=function statfd FD
Request file administration information about an open file. It returns
the same list of values as C<stat> on filenames.

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
sub creatfd($$)   { openfd $_[0], O_WRONLY()|O_CREAT()|O_TRUNC(), $_[1] }

=function fdopen FD, MODE
Converts a FD into an (buffered) FH.  You probably want to set binmode
after this.  MODE can be Perl-like '<', '>', '>>', or POSIX standard
'r', 'w', 'a'.  POSIX modes 'r+', 'w+', and 'a+' can probably not be
supported.
=cut

# This is implemented via CORE::open, because we need an Perl FH, not a
# FILE *.

sub fdopen($$)
{   my ($fd, $mode) = @_;
   
    $mode =~ m/^([rwa]\+?|\<|\>|\>>)$/
        or die "illegal fdopen() mode '$mode'\n";

    my $m = $1 eq 'r' ? '<' : $1 eq 'w' ? '>' : $1 eq 'a' ? '>>' : $1;

    die "fdopen() mode '$mode' (both read and write) is not supported\n"
        if substr($m,-1) eq '+';

    open my($fh), "$m&=", $fd;
    $fh;
}

#------------------
=section Additional
Zillions of Perl programs reimplement these functions. Let's simplify
code.

=function tellfd FD
Reports the location in the file. This call does not exist (not in POSIX,
nor on other UNIXes), however is a logical counterpart of the C<tell()> on
filenames.

=function rewindfd FD
Seek to the beginning of the file
=cut

sub tellfd($)     {seekfd $_[0], 0, SEEK_CUR() }
sub rewindfd()    {seekfd $_[0], 0, SEEK_SET() }

=chapter CONSTANTS

The following constants are exported, shown here with the values
discovered during installation of this module.

=for comment
#TABLE_FDIO_START

The constant names for this fdio module are inserted here during
installation.

=for comment
#TABLE_FDIO_END

You can limit the import to the C<SEEK_*> constants by explicitly
using the C<:seek> import tag.  Use the C<:mode> for all C<O_*>
constants, to be used with M<openfd()>.
=cut

sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $fdio->{$name};
    sub() {$val};
}

1;
