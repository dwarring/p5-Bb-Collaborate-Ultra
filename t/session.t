use warnings; use strict;
use Test::More tests => 7;
use Test::Fatal;
use Date::Parse;
use lib '.';
use t::Ultra;

SKIP: {
    my %t = t::Ultra->test_connection;
    my $connection = $t{connection};
    skip $t{skip} || 'skipping live tests', 7
	unless $connection;

    $connection->connect;

    my $start = time() + 60;
    my $end = $start + 900;

    use Bb::Ultra::Session;
    my $session;
    is exception {
	$session = Bb::Ultra::Session->put($connection, {
	    name => 'Test Session',
	    startTime => $start,
	    endTime   => $end,
	    },
	)
    }, undef, "session put - lives";

    is $session->name, 'Test Session', 'session name';
    is $session->startTime, $start, 'session start';
    is $session->endTime, $end, 'session end';

    my $user = Bb::Ultra::User->new({
	extId => 'testLaunchUser',
	displayName => 'David Warring',
	email => 'david.warring@gmail.com',
	firstName => 'David',
	lastName => 'Warring',
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

    my @enrollments = $session->enrollments;

    is exception { $session->del }, undef, 'session->del - lives';

}
