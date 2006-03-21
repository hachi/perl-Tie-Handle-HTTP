package Tie::Handle::HTTP;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Status;
use Errno qw(EIO EINVAL);
use Symbol;

use vars qw($VERSION);
$VERSION = '0.01';

sub DEBUGGING () { 0 }

# This doesn't work, please don't fix it without telling me how.
# sub open {
#     my $class = shift;
#     my $handle_ref = \$_[0]; shift;
#     my $uri = shift;
# 
#     my $symbol = Symbol::gensym;
# 
#     tie( *$symbol, __PACKAGE__, $uri );
# 
#     if ($handle_ref eq 'SCALAR') {
#         $$handle_ref = $symbol;
#     } elsif ($handle_ref eq 'GLOB') {
#         *$handle_ref = *$symbol;
#     }
# }

sub TIEHANDLE {
    my $class = shift;
    my $uri = shift;

    # Add configurable options for UserAgent
    my $ua = LWP::UserAgent->new( keep_alive => 5 );
    my $req = HTTP::Request->new( HEAD => $uri );
    my $res = $ua->request( $req );

    return unless $res->is_success;

    my $self = bless {}, (ref $class || $class);

    $self->{length} = $res->header( 'Content-Length' );
    $self->{pos} = 0;
    $self->{ua} = $ua;
    $self->{uri} = $uri;
    $self->{eof} = 0;

    warn "URI: $uri reports length of $self->{length} bytes.\n" if DEBUGGING;

    return $self;
}

sub READ {
    my $self = shift;
    my $buf = \$_[0]; shift;
    my ($len, $offset) = @_;
    
    defined( $$buf ) or $$buf = '';
    defined( $offset ) or $offset = 0;
    
    my $pos = $self->{pos};
    my $uri = $self->{uri};
    
    # Implement this area of functionality
    return unless ($len > 0);

    # Implement this area of functionality
    return unless ($offset >= 0);

    return 0 if ($self->EOF);

    my $start = $pos;
    my $end = $pos + $len - 1;

    warn "Requesting $start to $end bytes of $uri\n" if DEBUGGING;

    my $req = HTTP::Request->new(GET => $uri, [
        Range => "bytes=$start-$end",
    ], );

    my $res = $self->{ua}->request( $req );

    if ($res->is_error) {
        if ($res->code eq RC_REQUEST_RANGE_NOT_SATISFIABLE) {
            $self->{eof} = 1;
            return 0;
        }
        
        $! = EIO;
        return;
    }

    my $length = length( $res->content );

    $self->{pos} = $pos + $length;

    # Find out if read(2) clears to the end of the string or not
    substr( $$buf, $offset, $length ) = $res->content;

    return $length;
}

sub EOF {
    my $self = shift;

    return 1 if $self->{eof};

    return unless $self->{length};

    return $self->{pos} >= $self->{length};
}

sub GETC {
    my $self = shift;

    $self->READ( my $buf, 1 );
    return $buf;
}

sub TELL {
    my $self = shift;

    return $self->{pos};
}

sub SEEK {
    my $self = shift;
    my ($offset, $whence) = @_;

    if ($whence == 1) {
        $offset += $self->{pos};
    }
    elsif ($whence == 2) {
        my $len = $self->{length};
        if (defined( $len )) {
            $offset += $len;
        }
        else {
            $! = EINVAL;
            return 0;
        }
    }

    $self->{pos} = $offset;
    $self->{eof} = 0;
    return 1;
}

1;
__END__

=head1 NAME

Tie::Handle::HTTP - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Tie::Handle::HTTP;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Tie::Handle::HTTP, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Jonathan Steinert, E<lt>hachi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Six Apart, Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
