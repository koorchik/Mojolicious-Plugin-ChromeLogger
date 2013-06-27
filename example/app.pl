#!/usr/bin/env perl

use utf8;
use Mojolicious::Lite;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

plugin 'ChromeLogger';

get '/' => sub {
    my $self = shift;

    my $log = $self->app->log;

    $log->debug('Some debug here(С кириллицей)');
    $log->info('Some info here');
    $log->warn('Some warn here');
    $log->error('Some error here');
    $log->fatal('Some fatal here');

    $self->render( text => 'Open Chrome console' );
};

app->start;
