package Mojolicious::Plugin::ChromeLogger;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use Mojo::JSON;

use Mojo::Log::ChromeLogger;

our $VERSION = 0.02;

has 'chrome_log';

my %types_map = (
    'debug' => 'log',
    'info'  => 'info',
    'warn'  => 'warn',
    'error' => 'error',
    'fatal' => 'error',
);

sub register {
    my ( $self, $app ) = @_;

    $self->chrome_log( Mojo::Log::ChromeLogger->new() );
    $app->log( $self->chrome_log );

    $app->hook(
        after_dispatch => sub {
            my ($c) = @_;
            my $logs = $self->chrome_log->history;
            $self->chrome_log->history([]);

            # Leave static content untouched
            return if $c->stash('mojo.static');

            # Do not allow if not development mode
            return if $c->app->mode ne 'development';

            my $data = {
                version => $VERSION,
                columns => [ 'log', 'backtrace', 'type' ],
                rows    => []
            };

            # Logs: fatal, info, debug, error
            foreach my $msg (@$logs) {
                push @{ $data->{rows} },
                  [ $msg->[1], $msg->[2], $types_map{ $msg->[0] } ];
            }

            my $json       = Mojo::JSON->new()->encode($data);
            my $final_data = b($json)->encode('UTF-8')->b64_encode('');
            $c->res->headers->add( 'X-ChromeLogger-Data' => $final_data );

        }
    );
}

1;
