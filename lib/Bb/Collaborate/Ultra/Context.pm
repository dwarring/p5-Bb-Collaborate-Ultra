package Bb::Collaborate::Ultra::Context;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra';
__PACKAGE__->resource('contexts');
__PACKAGE__->load_schema(<DATA>);

__PACKAGE__->query_params(
    name => 'Str',
    extId => 'Str',
    );

sub associate_session {
    my $self = shift;
    my $class = ref($self) || die 'usage: $obj->associate_session($session)';
    my $session = shift;
    my $session_id = $session->can('id')
	? $session->id : $session;
    my $path = $self->path . '/sessions';
    $self->connection->post($class, { id => $session_id }, path => $path);
}

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
