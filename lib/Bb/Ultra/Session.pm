package Bb::Ultra::Session {
    use warnings; use strict;
    use Mouse;
    extends 'Bb::Ultra';
    has 'id' => (is => 'rw', isa => 'Str');
    has 'name' => (is => 'rw', isa => 'Str');
    has 'startTime' => (is => 'rw', isa => 'Str');
    has 'endTime' => (is => 'rw', isa => 'Str');
    has 'boundaryTime' => (is => 'rw', isa => 'Int');
    has 'guestUrl' => (is => 'rw', isa => 'Str');
    has 'allowGuest' => (is => 'rw', isa => 'Bool');
    has 'noEndDate' => (is => 'rw', isa => 'Bool');
    has 'showProfile' => (is => 'rw', isa => 'Bool');
    has 'participantCanUseTools' => (is => 'rw', isa => 'Bool');
    has 'canShareVideo' => (is => 'rw', isa => 'Bool');
    has 'canShareAudio' => (is => 'rw', isa => 'Bool');
    has 'canPostMessage' => (is => 'rw', isa => 'Bool');
    has 'canAnnotateWhiteboard' => (is => 'rw', isa => 'Bool');
    has 'mustBeSupervised' => (is => 'rw', isa => 'Bool');
    has 'openChair' => (is => 'rw', isa => 'Bool');
    has 'raiseHandOnEnter' => (is => 'rw', isa => 'Bool');
    has 'allowInSessionInvitees' => (is => 'rw', isa => 'Bool');
    has 'canDownloadRecording' => (is => 'rw', isa => 'Bool');
    has 'created' => (is => 'rw', isa => 'Str');
    has 'updated' => (is => 'rw', isa => 'Str');
}
1;
