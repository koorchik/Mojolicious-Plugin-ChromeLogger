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
            my $final_data = b($json)->b64_encode('');
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
            push @{ $self->logs }, [ $level, [ $_[-1] ], "at $filename:$line" ];
            $orig->(@_);
        };
    }
}

1;

=head1 NAME

Mojolicious::Plugin::ChromeLogger - Show Mojolicious logs in Google Chrome console

=head1 DESCRIPTION

L<Mojolicious::Plugin::ChromeLogger> pushes Mojolicious log messages to Google Chrome console. Works with any types of responses(even with JSON).
To view logs in Google Chrome you should install ChromeLogger extenstion. Logging works only in development mode.

See details here http://craig.is/writing/chrome-logger

=head1 USAGE

    use Mojolicious::Lite;

    plugin 'ChromeLogger';

    get '/' => sub {
        my $self = shift;

        app->log->debug('Some debug here');
        app->log->info('Some info here');
        app->log->warn('Some warn here');
        app->log->error('Some error here');
        app->log->fatal('Some fatal here');

        $self->render( text => 'Open Google Chrome console' );
    };

    app->start;

=head1 METHODS

L<Mojolicious::Plugin::ChromeLogger> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register condition in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious::Plugin::ConsoleLogger>

=head1 DEVELOPMENT

L<https://github.com/koorchik/Mojolicious-Plugin-ChromeLogger>

=head1 CREDITS

Inspired by L<Mojolicious::Plugin::ConsoleLogger>

=head1 AUTHORS

Viktor Turskyi koorchik@cpan.org

=cut
