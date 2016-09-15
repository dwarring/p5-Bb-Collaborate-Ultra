package Bb::Collaborate::Ultra::LaunchContext;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra';
use Bb::Collaborate::Ultra::User;
has 'user' => (isa => 'Bb::Collaborate::Ultra::User', is => 'rw', coerce => 1);

sub join_session {
    my $self = shift;
    my $session = shift;
    my $connection = shift || $session->connection
	or die "not connected";
    my $session_path = $session->path.'/url';
    my $data = $self->freeze;
    my $response = $connection->post($session_path, $data);
    my $msg = $response;
    $msg->{url};
}

__PACKAGE__->load_schema(<DATA>);
1;
# downloaded from https://xx-csa.bbcollab.com/documentation
__DATA__
               {
  "type" : "object",
  "id" : "UserLaunchContext",
  "properties" : {
    "returnUrl" : {
      "type" : "string"
    },
    "reconnectUrl" : {
      "type" : "string"
    },
    "locale" : {
      "type" : "string"
    },
    "launchingRole" : {
      "type" : "string",
      "enum" : [ "participant", "moderator", "presenter" ]
    },
    "editingPermission" : {
      "type" : "string",
      "enum" : [ "reader", "writer" ]
    },
    "originDomain" : {
      "type" : "string"
    },
    "user" : {
      "type" : "object",
      "id" : "User",
      "properties" : {
        "id" : {
          "type" : "string"
        },
        "lastName" : {
          "type" : "string"
        },
        "created" : {
          "type" : "string",
          "format" : "DATE_TIME"
        },
        "passwordModified" : {
          "type" : "string",
          "format" : "DATE_TIME"
        },
        "email" : {
          "type" : "string"
        },
        "ltiLaunchDetails" : {
          "type" : "object",
          "additionalProperties" : {
            "type" : "any"
          }
        },
        "avatarUrl" : {
          "type" : "string"
        },
        "userName" : {
          "type" : "string"
        },
        "displayName" : {
          "type" : "string"
        },
        "firstName" : {
          "type" : "string"
        },
        "extId" : {
          "type" : "string"
        },
        "modified" : {
          "type" : "string",
          "format" : "DATE_TIME"
        }
      }
    }
  }
}
