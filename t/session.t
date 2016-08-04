use warnings; use strict;
use Test::More tests => 14;
use Test::Fatal;
use Date::Parse;
use lib '.';
use t::Ultra;

SKIP: {
    my %t = t::Ultra->test_connection;
    my $connection = $t{connection};
    skip $t{skip} || 'skipping live tests', 14
	unless $connection;

    $connection->connect;

    my $start = time() + 60;
    my $end = $start + 900;

    use Bb::Ultra::Session;
    my $session;
    is exception {
	$session = Bb::Ultra::Session->post($connection, {
	    name => 'Test Session',
	    startTime => $start,
	    endTime   => $end,
	    },
	);
    }, undef, "session post - lives";

    is $session->name, 'Test Session', 'session name';
    is $session->startTime, $start, 'session start';
    is $session->endTime, $end, 'session end';

    $session->name('Test Session - Updated');

    my $updates = $session->_pending_updates;
    is_deeply $updates, { 'id' => $session->id, name => 'Test Session - Updated', startTime => $session->startTime, endTime => $session->endTime, }, 'updateable data';
    is exception { $session->put }, undef, 'put updates - lives';
    $updates = $session->_pending_updates;
    delete $updates->{active}; # ignore this
    is_deeply $updates, { 'id' => $session->id, , startTime => $session->startTime, endTime => $session->endTime,}, 'updates are flushed';
    my @enrollments = $session->enrollments;
    is scalar @enrollments, 0, 'no session enrolments yet';

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

    @enrollments = $session->enrollments;
    is scalar @enrollments, 1, 'user is now enrolled';
    my $enrollment = $enrollments[0];

    is $enrollment->editingPermission, 'reader';

    my @sessions = $connection->get( 'Bb::Ultra::Session' => {
	limit => 5,
    });

    ok scalar @sessions <= 5 && scalar @sessions > 0, 'get sessions - with limits';

    is exception { $session->del }, undef, 'session->del - lives';

}
