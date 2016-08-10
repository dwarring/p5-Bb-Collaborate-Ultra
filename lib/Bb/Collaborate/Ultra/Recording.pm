package Bb::Collaborate::Ultra::Recording;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra';
__PACKAGE__->resource('recordings');
__PACKAGE__->load_schema(<DATA>);

__PACKAGE__->query_params(
    name => 'Str',
    contextId => 'Str',
    startTime => 'Date',
    endTime => 'Date'
);
# downloaded from https://xx-csa.bbcollab.com/documentation
1;
__DATA__
                {
  "type" : "object",
  "id" : "Recording",
  "properties" : {
    "sessionStartTime" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "ownerId" : {
      "type" : "string"
    },
    "mediaName" : {
      "type" : "string"
    },
    "restricted" : {
      "type" : "boolean"
    },
    "endTime" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "editingPermission" : {
      "type" : "string",
      "enum" : [ "reader", "writer" ]
    },
    "modified" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "startTime" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "id" : {
      "type" : "string"
    },
    "canDownload" : {
      "type" : "boolean"
    },
    "duration" : {
      "type" : "integer"
    },
    "sessionName" : {
      "type" : "string"
    },
    "created" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "name" : {
      "type" : "string"
    }
  }
}
