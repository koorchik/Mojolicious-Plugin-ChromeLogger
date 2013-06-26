#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojolicious::Plugin::ChromeLogger' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Plugin::ChromeLogger $Mojolicious::Plugin::ChromeLogger::VERSION, Perl $], $^X" );
