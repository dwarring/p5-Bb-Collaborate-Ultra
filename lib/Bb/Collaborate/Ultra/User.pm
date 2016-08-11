package Bb::Collaborate::Ultra::User;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra';

has 'ltiLaunchDetails' => (isa => 'Any', is => 'rw');

use Mouse::Util::TypeConstraints;
coerce __PACKAGE__, from 'HashRef' => via {
    __PACKAGE__->new( $_ )
};
__PACKAGE__->resource('users');
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