package Bb::Collaborate::Ultra::SessionEnrollment;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra::DAO';
__PACKAGE__->resource('enrollments');
__PACKAGE__->load_schema(<DATA>);

=head1 NAME

Bb::Collaborate::Ultra::SessionEnrollment - Session enrollments

=head2 METHODS

See L<https://xx-csa.bbcollab.com/documentation#SessionEnrollment>

=cut

# downloaded from https://xx-csa.bbcollab.com/documentation
1;
__DATA__
               {
  "type" : "object",
  "id" : "SessionEnrollment",
  "properties" : {
    "id" : {
      "type" : "string"
    },
    "userId" : {
      "type" : "string"
    },
    "launchingRole" : {
      "type" : "string",
      "enum" : [ "participant", "moderator", "presenter" ]
    },
    "permanentUrl" : {
      "type" : "string"
    },
    "editingPermission" : {
      "type" : "string",
      "enum" : [ "reader", "writer" ]
    }
  }
}
