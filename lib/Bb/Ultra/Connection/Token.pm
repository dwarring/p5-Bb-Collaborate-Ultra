package Bb::Ultra::Connection::Token;
    use warnings; use strict;
    use Moo;
    use Bb::Ultra::Types;
    has 'access_token' => (is => 'rw', isa => Str);
    has 'expires_in' => (is => 'rw', isa => Int);

1;
