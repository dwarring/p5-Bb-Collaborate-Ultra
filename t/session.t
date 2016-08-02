use warnings; use strict;
use Test::More tests => 4;
use Test::Fatal;
use Date::Parse;
use lib '.';
use t::Ultra;

SKIP: {
    my %t = t::Ultra->test_connection;
    my $connection = $t{connection};
    skip $t{skip} || 'skipping live tests', 4
	unless $connection;

    $connection->connect;

    use Bb::Ultra::Session;
    my $session;
    is exception {
	$session = Bb::Ultra::Session->put($connection, {
	    name => 'Test Session',
	    startTime => str2time "2016-12-01T21:32:00.937Z",
	    endTime   => str2time "2016-12-01T22:32:00.937Z",
	    },
	)
    }, undef, "session put - lives";

    my $user = Bb::Ultra::User->new({
	email => 'arnold.gerard@blackboard.com',
	firstName => 'Arnold',
	lastName => 'Gerard',
    });

    my $url;
    is exception {
	$url = $session->launch({
	    launchingRole => 'moderator',
	    editingPermission => 'reader',
	    user => $user,
	 });
    }, undef, 'session launch_context - lives';

    ok $url, "got launch_context url";
    warn "url: $url";

    is exception { $session->del }, undef, 'session->del - lives';

}
