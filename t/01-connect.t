use warnings; use strict;
use Test::More tests => 15;
use Test::Fatal;

use lib '.';
use t::Ultra;
use Date::Parse;
use Scalar::Util qw<looks_like_number>;

SKIP: {
    my %t = t::Ultra->test_connection;
    my $connection = $t{connection};
    skip $t{skip} || 'skipping live tests', 15
	unless $connection;

    ok $connection->issuer, 'issuer';
    ok $connection->secret, 'secret';
    ok $connection->host, 'host';

    is exception { $connection->connect; }, undef, "connection lives";

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

    my $msg = $connection->put(
	'Bb::Ultra::Session' => {
	    name => 'Test Session',
	    startTime => str2time "2016-12-01T21:32:00.937Z",
	    endTime   => str2time "2016-12-01T22:32:00.937Z",
	});
    my $session = Bb::Ultra::Session->construct($msg);
    ok $session->created, "session creation";
    ok looks_like_number $session->created, "created data-type"
	or diag "created: " .  $session->created;

    my $session_id = $session->id;
    $session = undef;

    $session = $connection->get('Bb::Ultra::Session' => {
	id => $session_id,
    });

    ok $session->created, "session creation";
    ok looks_like_number $session->created, "created data-type"
	or diag "created: " .  $session->created;

    is exception {
	$connection->del('Bb::Ultra::Session' => {
	    id => $session->id,
	});
    }, undef, "session deletion lives";
}

done_testing;
