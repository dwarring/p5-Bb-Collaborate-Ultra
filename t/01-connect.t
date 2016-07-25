use warnings; use strict;
use Test::More tests => 10;
use Test::Fatal;
use version;

use lib '.';
use t::Ultra;

use Bb::Ultra::Connection;

 SKIP: {
     my %t = t::Ultra->test_connection;
     my $connection = $t{connection};
     skip $t{skip} || 'skipping live tests', 10
	 unless $connection;

     ok $connection->issuer, 'issuer';
     ok $connection->secret, 'secret';
     ok $connection->host, 'host';

     is exception { $connection->connect }, undef, "connection lives";

     my $token_start = $connection->token_start;
     ok $token_start, 'token_start';

     my $t = time();
     ok $token_start > $t - 60 && $token_start <= $t + 60, 'token_start'
	 or diag "time:$t token_start:$token_start";

     my $token = $connection->token;

     isa_ok $token, 'Bb::Ultra::Connection::Token', 'token';
     ok $token->access_token, 'token_access';
     my $expires = $token->expires_in;
     ok $expires, 'expires_in';
     ok $expires > 0 && $expires <= 1000, 'expires_in'
	 or diag "expires: $expires";
}

done_testing;
