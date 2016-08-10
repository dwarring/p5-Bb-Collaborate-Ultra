use warnings; use strict;
use Test::More tests => 24;
use Test::Fatal;
use JSON;
# ----------------------------------------------------------------
use Bb::Collaborate::Ultra::Session;

ok(Bb::Collaborate::Ultra::Session->can('startTime'), "accessor introspection");

my $types = Bb::Collaborate::Ultra::Session->_property_types;

ok exists $types->{startTime}, "property_types introspection"
    or diag explain {'session.types' => $types};

my $now = time;
my %session_data = (
    id => 'abc123456',
    startTime => $now,
    name => 'test session object',
    );

isnt exception { Bb::Collaborate::Ultra::Session->new(\%session_data)}, undef, 'create session without required - dies';

$session_data{endTime} = $session_data{startTime} + 30 * 60;
my $session;

is exception { $session = Bb::Collaborate::Ultra::Session->new(\%session_data)}, undef, 'create session with required - lives';

isa_ok $session, 'Bb::Collaborate::Ultra::Session', 'session';
is $session->id, 'abc123456', 'session->id';

isnt exception { $session->guestRole('lacky') }, undef, 'enum - invalid';
isnt  $session->guestRole, 'lacky', 'enum - invalid';

is exception { $session->guestRole('participant') }, undef, 'enum - valid';
is  $session->guestRole, 'participant', 'enum - valid';

# ----------------------------------------------------------------
use Bb::Collaborate::Ultra::User;

my %user_data = (
    'id' => 'xyz345',
    'userName' => 'Alice'
    );

my $user;
is exception { $user = Bb::Collaborate::Ultra::User->new(\%user_data)}, undef, 'create user - lives';

isa_ok $user, 'Bb::Collaborate::Ultra::User', 'user';
is $user->id, 'xyz345', 'user->id';
is $user->userName, 'Alice', 'user->userName';
my $thawed;
is exception { $thawed = from_json $user->freeze, }, undef, 'user freeze/thaw round trip - lives';
is_deeply $thawed, \%user_data, 'user freeze/thaw round trip - data';

# ----------------------------------------------------------------
use Bb::Collaborate::Ultra::LaunchContext;

my %launch_context_data = (
    'launchingRole' => 'participant',
    'user' => {
	'id' => 'xyz248',
	'userName' => 'Bob'
    },
    );

my $launch_context;
is exception { $launch_context = Bb::Collaborate::Ultra::LaunchContext->new(\%launch_context_data)}, undef, 'create launch_context - lives';

isa_ok $launch_context, 'Bb::Collaborate::Ultra::LaunchContext', 'launch_context';
is $launch_context->launchingRole, 'participant', 'launch_context->launchingRole';

$user = $launch_context->user;

isa_ok $user, 'Bb::Collaborate::Ultra::User', 'launch_context->user';
is $user->id, 'xyz248', 'launch_context->user->id';
is $user->userName, 'Bob', 'launch_context->user->userName';

is exception { $thawed = from_json $launch_context->freeze }, undef, 'launch context freeze/thaw round-trip - lives';
is_deeply $thawed, \%launch_context_data, 'launch context freeze/thaw round trip - data';

# ----------------------------------------------------------------
done_testing;
