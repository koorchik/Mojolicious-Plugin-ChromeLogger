package Mojolicious::Plugin::ChromeLogger;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use Mojo::JSON;

our $VERSION = 0.01;

has logs => sub { return [] };

my %types_map = (
    'debug' => 'log',
    'info'  => 'info',
    'warn'  => 'warn',
    'error' => 'error',
    'fatal' => 'error',
);

sub register {
    my ( $self, $app ) = @_;

    # override Mojo::Log->log
    no strict 'refs';
    my $stash = \%{"Mojo::Log::"};
    my $orig  = delete $stash->{"log"};

    *{"Mojo::Log::log"} = sub {
        push @{ $self->logs }, [ $_[1], $_[-1] ];
        $orig->(@_);
    };

    $app->hook(
        after_dispatch => sub {
            my ($c) = @_;
            my $logs = $self->logs;

            # Leave static content untouched
            return if $c->stash('mojo.static');

            # Do not allow if not development mode
            return if $c->app->mode ne 'development';

            my $data = {
                version => '0.01',
                columns => [ 'log', 'backtrace', 'type' ],
                rows    => []
            };

            # Logs: fatal, info, debug, error
            foreach my $msg (@$logs) {
                push @{ $data->{rows} },
                  [ $msg->[1], undef, $types_map{ $msg->[0] } ];
            }

            my $json       = Mojo::JSON->new()->encode($data);
            my $final_data = b($json)->encode('UTF-8')->b64_encode('');
            $c->res->headers->add( 'X-ChromeLogger-Data' => $final_data );

            $self->logs( [] );
        }
    );
}

1;
