package Mojo::Log::ChromeLogger;
use Mojo::Base 'Mojo::Log';

has 'history' => sub { return [] };

sub debug {
    my $self = shift;

    $self->_append_to_history( 'debug' => @_ );
    $self->SUPER::debug(@_);
}

sub info {
    my $self = shift;

    $self->_append_to_history( 'info' => @_ );
    $self->SUPER::info(@_);
}

sub warn {
    my $self = shift;

    $self->_append_to_history( 'warn' => @_ );
    $self->SUPER::warn(@_);
}

sub error {
    my $self = shift;

    $self->_append_to_history( 'error' => @_ );
    $self->SUPER::error(@_);
}

sub fatal {
    my $self = shift;

    $self->_append_to_history( 'fatal' => @_ );
    $self->SUPER::fatal(@_);
}

sub _append_to_history {
    my ( $self, $level, @lines ) = @_;

    my ($package, $file, $line) = caller(1);
    push @{ $self->history }, [ $level, join( ' ', @lines ), "$file:$line"];

}

1;