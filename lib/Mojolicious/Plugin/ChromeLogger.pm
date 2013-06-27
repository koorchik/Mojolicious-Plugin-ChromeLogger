package Mojolicious::Plugin::ChromeLogger;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::ByteStream qw/b/;
use Mojo::JSON;

our $VERSION = 0.02;

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

    # We do use monkey patch instead of inheriting Mojo::Log to be compatible with Log::Any::Adapter::Mojo
    $self->_monkey_patch_logger();

    $app->hook(
        after_dispatch => sub {
            my ($c) = @_;
            my $logs = $self->logs;

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

            $self->logs( [] );
        }
    );
}

sub _monkey_patch_logger {
    my ($self) = @_;

    no strict 'refs';
    my $stash = \%{"Mojo::Log::"};

    foreach my $level (qw/debug info warn error fatal/) {
        my $orig  = delete $stash->{$level};

        *{"Mojo::Log::$level"} = sub {
            my ($package, $filename, $line) = caller;
            push @{ $self->logs }, [ $level, $_[-1], "$filename:$line" ];
            $orig->(@_);
        };
    }
}

1;
