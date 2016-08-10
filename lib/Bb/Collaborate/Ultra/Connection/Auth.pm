package Bb::Collaborate::Ultra::Connection::Auth {
    use Mouse;
    extends 'Bb::Collaborate::Ultra';
    use warnings; use strict;
    __PACKAGE__->resource('token');
    has 'access_token' => (is => 'rw', isa => 'Str');
    has 'expires_in' => (is => 'rw', isa => 'Int');
}
1;
