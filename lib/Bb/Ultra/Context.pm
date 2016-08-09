package Bb::Ultra::Context;
use warnings; use strict;
use Mouse;
extends 'Bb::Ultra';
__PACKAGE__->resource('contexts');
__PACKAGE__->load_schema(<DATA>);

__PACKAGE__->query_params(
    name => 'Str',
    extId => 'Str',
);
# downloaded from https://xx-csa.bbcollab.com/documentation
1;
__DATA__
                {
  "type" : "object",
  "id" : "Context",
  "properties" : {
    "id" : {
      "type" : "string"
    },
    "title" : {
      "type" : "string"
    },
    "created" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "name" : {
      "type" : "string",
      "required" : true
    },
    "label" : {
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
