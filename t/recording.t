use warnings; use strict;
use Test::More tests => 3;
use Test::Fatal;
use Date::Parse;
use lib '.';
use t::Ultra;
use Bb::Ultra::Recording;

SKIP: {
    my %t = t::Ultra->test_connection;
    my $connection = $t{connection};
    skip $t{skip} || 'skipping live tests', 3
	unless $connection;

    $connection->connect;

    my @recordings = $connection->get( 'Bb::Ultra::Recording' => {
	limit => 5,
	startTime => time() - 7 * 60 * 60 * 24,
    });

    skip "no recordings found", 2
        unless @recordings;
    ok scalar @recordings <= 5 && scalar @recordings > 0, 'get sessions - with limits';

    my $recording = $recordings[0];
    isa_ok $recording, 'Bb::Ultra::Recording';
    ok $recording->sessionStartTime;

}
