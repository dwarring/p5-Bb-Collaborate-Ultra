package Bb::Collaborate::Ultra::Connection::Auth;
use Mouse;
extends 'Bb::Collaborate::Ultra';
use warnings; use strict;
__PACKAGE__->resource('token');
has 'access_token' => (is => 'rw', isa => 'Str');
has 'expires_in' => (is => 'rw', isa => 'Int');
has '_leased' => (is => 'rw', isa => 'Date');

sub expiry_time {
    my $self = shift;
    $self->_leased + $self->expires_in;
}

1;
