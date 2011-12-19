use warnings;
use strict;

package POSIX::1003::Termios;
use base 'POSIX::1003';

my @speed = qw/
 B0 B110 B1200 B134 B150 B1800 B19200 B200 B2400
 B300 B38400 B4800 B50 B600 B75 B9600
 /;

my @flags   = qw/
 BRKINT CLOCAL ECHONL HUPCL ICANON ICRNL IEXTEN IGNBRK IGNCR IGNPAR
 INLCR INPCK ISIG ISTRIP IXOFF IXON NCCS NOFLSH OPOST PARENB PARMRK
 PARODD TOSTOP VEOF VEOL VERASE VINTR VKILL VMIN VQUIT VSTART VSTOP
 VSUSP VTIME
 /;

my @actions = qw/
 TCSADRAIN TCSANOW TCOON TCIOFLUSH TCOFLUSH TCION TCIFLUSH
 TCSAFLUSH TCIOFF TCOOFF
 /;

my @functions = qw/
 cfgetispeed cfgetospeed cfsetispeed cfsetospeed
 tcdrain tcflow tcflush tcgetattr tcsendbreak tcsetattr
 ttyname
 /;

our %EXPORT_TAGS =
 ( speed     => \@speed
 , flags     => \@flags
 , actions   => \@actions
 , constants => [@speed, @flags, @actions]
 , functions => \@functions
 );

=chapter NAME

POSIX::1003::Termios - POSIX general terminal interface

=chapter SYNOPSIS

  use POSIX::Termios qw(:speed);
  $termios = POSIX::Termios->new;
  $ispeed = $termios->getispeed;
  $termios->setospeed(B9600);

  use POSIX::Termios qw(:functions :actions);
  tcsendbreak($fd, $duration);
  tcflush($fd, TCIFLUSH);

  $tty  = ttyname($fd);
  $tty  = ttyname($fh->fileno);

=chapter DESCRIPTION

This module provides an interface to the "General Terminal Interfaces",
as specified by POSIX. The actual implementation is part of POSIX.xs

=chapter METHODS

=section Constructors

=c_method new

Create a new Termios object. This object will be destroyed automatically
when it is no longer needed. A Termios object corresponds to the
termios C struct.

  $termios = POSIX::1003::Termios->new;

=section Accessors

=method getattr [FD]

Get terminal control attributes (POSIX function C<tcgetattr>). Pass a file
descriptor, which defaults to C<0> (stdin). Returns C<undef> on failure.

  # Obtain the attributes for stdin
  $termios->getattr(0);
  $termios->getattr();

  # Obtain the attributes for stdout
  $termios->getattr(1);

=method setattr FD, FLAGS
Set terminal control attributes (POSIX function C<tcsetattr>).  Returns
C<undef> on failure.

  # Set attributes immediately for stdout.
  $termios->setattr(1, TCSANOW);

=method getcc INDEX
Retrieve a value from the C<c_cc> field of a termios object. The c_cc field is
an array so an index must be specified.
  $c_cc[1] = $termios->getcc(1);

=method getcflag
Retrieve the C<c_cflag> field of a termios object.
  $c_cflag = $termios->getcflag;

=method getiflag
Retrieve the C<c_iflag> field of a termios object.
  $c_iflag = $termios->getiflag;

=method getispeed
Retrieve the input baud rate.
  $ispeed = $termios->getispeed;

=method getlflag
Retrieve the C<c_lflag> field of a termios object.
  $c_lflag = $termios->getlflag;

=method getoflag
Retrieve the C<c_oflag> field of a termios object.
  $c_oflag = $termios->getoflag;

=method getospeed
Retrieve the output baud rate.
  $ospeed = $termios->getospeed;

=method setcc VALUE, INDEX
Set a value in the C<c_cc> field of a termios object.  The c_cc field is an
array so an index must be specified.
  $termios->setcc(VEOF, 1 );

=method setcflag FLAGS
Set the C<c_cflag> field of a termios object.
  $termios->setcflag( $c_cflag | CLOCAL );

=method setiflag FLAGS
Set the C<c_iflag> field of a termios object.
  $termios->setiflag( $c_iflag | BRKINT );

=method setispeed
Set the input baud rate.  Returns C<undef> on failure.
  $termios->setispeed( B9600 );

=method setlflag FLAGS
Set the C<c_lflag> field of a termios object.
  $termios->setlflag( $c_lflag | ECHO );

=method setoflag FLAGS
Set the c_oflag field of a termios object.
  $termios->setoflag( $c_oflag | OPOST );

=method setospeed
Set the output baud rate.
  $termios->setospeed( B9600 );

=method ttyname FD
Returns the path to the special device which relates to the file-descriptor.
See also M<POSIX::1003::Proc::ctermid()>
  $tty  = ttyname($fd);
  $tty  = ttyname($fh->fileno);

=section Constants

=over 4

=item Available baudrates (ispeed and ospeed), export tag C<:speed>.

  B0 B50 B75 B110 B134 B150 B200 B300 B600 B1200
  B1800 B2400 B4800 B9600 B19200 B38400

=item Interface values (getattr and setattr), export tag C<:actions>.

  TCSADRAIN TCSANOW TCOON TCIOFLUSH TCOFLUSH TCION TCIFLUSH
  TCSAFLUSH TCIOFF TCOOFF

=item c_cc field values, export tag C<:flags> as have all following constants.

  VEOF VEOL VERASE VINTR VKILL VQUIT VSUSP VSTART VSTOP VMIN
  VTIME NCCS

=item c_cflag field values

  CLOCAL CREAD CSIZE CS5 CS6 CS7 CS8 CSTOPB HUPCL PARENB PARODD

=item c_iflag field values

  BRKINT ICRNL IGNBRK IGNCR IGNPAR INLCR INPCK ISTRIP IXOFF
  IXON PARMRK

=item c_lflag field values

  ECHO ECHOE ECHOK ECHONL ICANON IEXTEN ISIG NOFLSH TOSTOP

=item c_oflag field values

  OPOST

=back

=cut

1;
