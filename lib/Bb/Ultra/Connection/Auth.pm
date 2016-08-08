package Bb::Ultra::Connection::Auth {
    use Mouse;
    extends 'Bb::Ultra';
    use warnings; use strict;
    __PACKAGE__->resource('token');
    has 'access_token' => (is => 'rw', isa => 'Str');
    has 'expires_in' => (is => 'rw', isa => 'Int');
}
1;
