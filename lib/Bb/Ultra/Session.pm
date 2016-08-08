package Bb::Ultra::Session;
use warnings; use strict;
use Mouse;
use JSON;
extends 'Bb::Ultra';
__PACKAGE__->resource('sessions');
__PACKAGE__->load_schema(<DATA>);

__PACKAGE__->query_params(
    name => 'Str',
    userId => 'Str',
    contextId => 'Str',
    startTime => 'Date',
    endTime => 'Date',
    sessionCategory => 'Str',
);

use Bb::Ultra::LaunchContext;
use Bb::Ultra::SessionEnrollment;

sub launch {
    my $self = shift;
    my $data = shift;
    my $connection = shift || $self->connection;
    my $path = $self->path.'/url';
    my $response = $connection->post( 'Bb::Ultra::LaunchContext' => $data, path => $path);
    my $msg = from_json $response;
    $msg->{url};
}

sub enrollments {
    my $self = shift;
    my $data = shift;
    my $connection = shift || $self->connection;
    my $path = $self->path.'/enrollments';
    $connection->get( 'Bb::Ultra::SessionEnrollment' => {}, path => $path, parent => $self);
}

1;
# downloaded from https://xx-csa.bbcollab.com/documentation
__DATA__
                {
  "type" : "object",
  "id" : "Session",
  "properties" : {
    "telephonyPhoneNumber" : {
      "type" : "string"
    },
    "courseRoomEnabled" : {
      "type" : "boolean"
    },
    "noEndDate" : {
      "type" : "boolean"
    },
    "participantCanUseTools" : {
      "type" : "boolean"
    },
    "endTime" : {
      "type" : "string",
      "required" : true,
      "format" : "DATE_TIME"
    },
    "guestRole" : {
      "type" : "string",
      "enum" : [ "participant", "moderator", "presenter" ]
    },
    "openChair" : {
      "type" : "boolean"
    },
    "showProfile" : {
      "type" : "boolean"
    },
    "startTime" : {
      "type" : "string",
      "required" : true,
      "format" : "DATE_TIME"
    },
    "id" : {
      "type" : "string"
    },
    "ltiParticipantRole" : {
      "type" : "string",
      "enum" : [ "participant", "moderator", "presenter" ]
    },
    "occurrenceType" : {
      "type" : "string",
      "enum" : [ "S", "P" ]
    },
    "canDownloadRecording" : {
      "type" : "boolean"
    },
    "created" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "description" : {
      "type" : "string"
    },
    "occurrences" : {
      "type" : "array",
      "items" : {
        "type" : "object",
        "id" : "SessionOccurrence",
        "properties" : {
          "id" : {
            "type" : "string"
          },
          "startTime" : {
            "type" : "string",
            "format" : "DATE_TIME"
          },
          "active" : {
            "type" : "boolean"
          },
          "endTime" : {
            "type" : "string",
            "format" : "DATE_TIME"
          }
        }
      }
    },
    "name" : {
      "type" : "string",
      "required" : true
    },
    "raiseHandOnEnter" : {
      "type" : "boolean"
    },
    "canAnnotateWhiteboard" : {
      "type" : "boolean"
    },
    "recurrenceRule" : {
      "type" : "object",
      "id" : "RecurrenceRule",
      "properties" : {
        "recurrenceEndType" : {
          "type" : "string",
          "enum" : [ "on_date", "after_occurrences_count" ]
        },
        "daysOfTheWeek" : {
          "type" : "array",
          "items" : {
            "type" : "string",
            "enum" : [ "mo", "tu", "we", "th", "fr", "sa", "su" ]
          }
        },
        "recurrenceType" : {
          "type" : "string",
          "enum" : [ "daily", "weekly", "monthly" ]
        },
        "interval" : {
          "type" : "string",
          "enum" : [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" ]
        },
        "numberOfOccurrences" : {
          "type" : "integer"
        },
        "endDate" : {
          "type" : "string",
          "format" : "DATE_TIME"
        }
      }
    },
    "sessionCategory" : {
      "type" : "string",
      "enum" : [ "default", "course" ]
    },
    "canPostMessage" : {
      "type" : "boolean"
    },
    "mustBeSupervised" : {
      "type" : "boolean"
    },
    "createdTimezone" : {
      "type" : "string"
    },
    "moderatorUrl" : {
      "type" : "string"
    },
    "allowGuest" : {
      "type" : "boolean"
    },
    "telephonyEnabled" : {
      "type" : "boolean"
    },
    "editingPermission" : {
      "type" : "string",
      "enum" : [ "reader", "writer" ]
    },
    "modified" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "guestUrl" : {
      "type" : "string"
    },
    "canShareVideo" : {
      "type" : "boolean"
    },
    "sessionExitUrl" : {
      "type" : "string"
    },
    "boundaryTime" : {
      "type" : "string",
      "enum" : [ "0", "15", "30", "45", "60" ]
    },
    "active" : {
      "type" : "boolean"
    },
    "allowInSessionInvitees" : {
      "type" : "boolean"
    },
    "canShareAudio" : {
      "type" : "boolean"
    }
  }
}

