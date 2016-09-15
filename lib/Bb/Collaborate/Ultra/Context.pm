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
    my $session = shift;

    die 'usage: $context->associate_session($session)'
	unless ref($self) && ref($session);
    my $session_id = $session->id;
    my $path = $self->path . '/sessions';
    my $json = $session->freeze( { id => $session_id } );
    $self->connection->post($path, $json );
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
