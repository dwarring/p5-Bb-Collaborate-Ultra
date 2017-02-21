package Bb::Collaborate::Ultra::Session::Log;
use warnings; use strict;
use Mouse;
use JSON;
extends 'Bb::Collaborate::Ultra::DAO';
use Mouse::Util::TypeConstraints;

=head1 NAME

Bb::Collaborate::Ultra::Session::Log

=head1 DESCRIPTION

Session logging class.

=head1 EXAMPLE

    my @sessions =  Bb::Collaborate::Ultra::Session->get($connection, {contextId => $context_id});
    for my $session (@sessions) {
	print "Session: ". $session->name . "\n";
	my @logs = $session->logs;

	for my $log (@logs) {
	    say "\tOpened: " .(scalar localtime $log->opened);
	    for my $attendee ($log->attendees) {
		my $first_join;
		my $elapsed = 0;
		for my $attendance (@{$attendee->attendance}) {
		    my $joined = $attendance->joined;
		    $first_join = $joined
			if !$first_join || $first_join > $joined;
		    $elapsed += $attendance->left - $joined;
		}
		say sprintf("\tUser %s (%s) joined at %s, stayed %d minutes", $attendee->externalUserId, $attendee->displayName, (scalar localtime $first_join), $elapsed / 60);
	    }
	    say "\tClosed: " .(scalar localtime $log->closed);
	}
    }

=head1 METHODS

This class supports the `get` method as described in L<https://xx-csa.bbcollab.com/documentation#Attendee-collection>.

=cut
    
coerce __PACKAGE__, from 'HashRef' => via {
    __PACKAGE__->new( $_ )
};
 
__PACKAGE__->resource('instances');
__PACKAGE__->load_schema(<DATA>);

=head2 attendees

Logs individual attendances for this session.

=cut

sub attendees {
    my $self = shift;
    my $connection = shift || $self->connection;
    my $path = $self->path.'/attendees';
    require Bb::Collaborate::Ultra::Session::Log::Attendee;
    Bb::Collaborate::Ultra::Session::Log::Attendee->get($connection => {}, path => $path, parent => $self);
}

# **NOT DOCUMENTED** in https://xx-csa.bbcollab.com/documentation
# schema has been reversed engineered
1;
__DATA__
{
    "type" : "object",
    "id" : "SessionLog",
    "properties" : {
        "id" : {
            "type" : "string"
        },
        "opened" : {
            "type" : "string",
            "format" : "DATE_TIME"
        },
        "closed" : {
            "type" : "string",
            "format" : "DATE_TIME"
        }
    }
}
