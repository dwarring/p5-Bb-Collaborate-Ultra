use warnings; use strict;
use Test::More tests => 20;
use Test::Fatal;
use JSON;
# ----------------------------------------------------------------
use Bb::Ultra::Session;

ok(Bb::Ultra::Session->can('startTime'), "accessor introspection");

my $types = Bb::Ultra::Session->_property_types;

ok exists $types->{startTime}, "property_types introspection"
    or diag explain {'session.types' => $types};

my $now = time;
my %session_data = (
    id => 'abc123456',
    startTime => $now,
    name => 'test session object',
    );

isnt exception { Bb::Ultra::Session->new(\%session_data)}, undef, 'create session without required - dies';

$session_data{endTime} = $session_data{startTime} + 30 * 60;
my $session;

is exception { $session = Bb::Ultra::Session->new(\%session_data)}, undef, 'create session with required - lives';

isa_ok $session, 'Bb::Ultra::Session', 'session';
is $session->id, 'abc123456', 'session->id';

# ----------------------------------------------------------------
use Bb::Ultra::User;

my %user_data = (
    'id' => 'xyz345',
    'userName' => 'Alice'
    );

my $user;
is exception { $user = Bb::Ultra::User->new(\%user_data)}, undef, 'create user - lives';

isa_ok $user, 'Bb::Ultra::User', 'user';
is $user->id, 'xyz345', 'user->id';
is $user->userName, 'Alice', 'user->userName';
my $thawed;
is exception { $thawed = from_json $user->freeze, }, undef, 'user freeze/thaw round trip - lives';
is_deeply $thawed, \%user_data, 'user freeze/thaw round trip - data';

# ----------------------------------------------------------------
use Bb::Ultra::LaunchContext;

my %launch_context_data = (
    'launchingRole' => 'participant',
    'user' => {
	'id' => 'xyz248',
	'userName' => 'Bob'
    },
    );

my $launch_context;
is exception { $launch_context = Bb::Ultra::LaunchContext->new(\%launch_context_data)}, undef, 'create launch_context - lives';

isa_ok $launch_context, 'Bb::Ultra::LaunchContext', 'launch_context';
is $launch_context->launchingRole, 'participant', 'launch_context->launchingRole';

$user = $launch_context->user;

isa_ok $user, 'Bb::Ultra::User', 'launch_context->user';
is $user->id, 'xyz248', 'launch_context->user->id';
is $user->userName, 'Bob', 'launch_context->user->userName';

is exception { $thawed = from_json $launch_context->freeze }, undef, 'launch context freeze/thaw round-trip - lives';
is_deeply $thawed, \%launch_context_data, 'launch context freeze/thaw round trip - data';

# ----------------------------------------------------------------
done_testing;
