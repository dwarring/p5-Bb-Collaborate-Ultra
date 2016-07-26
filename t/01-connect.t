use warnings; use strict;
use Test::More tests => 12;
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

     my $auth_start = $connection->auth_start;
     ok $auth_start, 'auth_start';

     my $t = time();
     ok $auth_start > $t - 60 && $auth_start <= $t + 60, 'auth_start'
	 or diag "time:$t auth_start:$auth_start";

     my $auth = $connection->auth;

     isa_ok $auth, 'Bb::Ultra::Connection::Auth', 'auth';
     ok $auth->access_token, 'access_token';
     my $expires = $auth->expires_in;
     ok $expires, 'expires_in';
     ok $expires > 0 && $expires <= 1000, 'expires_in'
	 or diag "expires: $expires";

     use Bb::Ultra::Session;
     use JSON;
     my $session =  Bb::Ultra::Session->new( {
	 name => 'Test Session',
	 startTime => "2016-12-01T21:32:00.937Z",
	 endTime   => "2016-12-01T22:32:00.937Z",
     });
     my %data  = map { $_ => $session->$_ } (qw<name startTime endTime>);
     my $json = to_json(\%data);
     $connection->client->POST('sessions',
		   $json,
		   {
		       'Content-Type' => 'application/json',
		       'Authorization' => 'Bearer ' . $connection->auth->access_token,	
		   },
	 );
     my $result = $connection->response_data;
     is ref $result, 'HASH', 'response data';
     $session = Bb::Ultra::Session->new($result);

     ok $session->created, "session creation";
}

done_testing;
