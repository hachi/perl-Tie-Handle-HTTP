#!/usr/bin/perl

use warnings;
use strict;
use Tie::Handle::HTTP;
use Test::More 'no_plan'; # tests => 10;

ok( tie( *FOO, 'Tie::Handle::HTTP', 'http://hachi.kuiki.net/stuff/test.txt' ), "Tie succeeded" );

ok( tell( FOO ) == 0, "Start at 0" );
readmatch( "Lorem ipsum dolor sit amet" );
readmatch( ", consectetuer adipiscing elit" );
seek( FOO, 0, 0 );
ok( tell( FOO ) == 0, "Seek to 0" );
readmatch( "Lorem ipsum dolor sit amet" );
readmatch( ", consectetuer adipiscing elit" );
readmatch( ", sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat." );

my $string = "Eodem modo typi, qui nunc nobis videntur parum clari, fiant sollemnes in futurum.";
seek( FOO, 0-length( $string ), 2 );

sub readmatch {
    my $string = shift;
    my $length = length( $string );

    my $pos = tell( FOO );

    {
        diag( "Requesting $length bytes: '$string'" );

        my $bytes = read( FOO, my $content, $length );

        diag( "Got $bytes bytes: '$content'" );

        ok( $bytes == $length, "Read of $length succeeded" );
        ok( $content eq $string, "Read of string succeeded" );
    }

    seek( FOO, 0-$length, 1 );

    ok( tell( FOO ) == $pos, "seek took us back where we started: $pos" );
    
    {
        diag( "Requesting $length bytes: '$string'" );

        my $bytes = read( FOO, my $content, $length );

        diag( "Got $bytes bytes: '$content'" );

        ok( $bytes == $length, "Read of $length succeeded" );
        ok( $content eq $string, "Read of string succeeded" );
    }
}
