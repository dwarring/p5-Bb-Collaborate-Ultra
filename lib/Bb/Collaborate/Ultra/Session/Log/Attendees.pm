package Bb::Collaborate::Ultra::Session::Log::Attendees;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra::DAO';
use Bb::Collaborate::Ultra::Session::Log::Attendee;
use Mouse::Util::TypeConstraints;

subtype 'ArrayOfAttendees',
    as 'ArrayRef[Bb::Collaborate::Ultra::Session::Log::Attendee]';

coerce 'ArrayOfAttendees',
    from 'ArrayRef[HashRef]',
    via { [ map {Bb::Collaborate::Ultra::Session::Log::Attendee->new($_)} (@$_) ] };

has 'results' => (isa => 'ArrayOfAttendees', is => 'rw', coerce => 1);

=head1 NAME

Bb::Collaborate::Ultra::Session::Log::Attendees

=head1 DESCRIPTION

Session Attendee report.

=head1 METHODS

See L<https://xx-csa.bbcollab.com/documentation#Attendee-collection>

=cut

coerce __PACKAGE__, from 'HashRef' => via {
    __PACKAGE__->new( $_ )
};
 
__PACKAGE__->resource('attendees');
__PACKAGE__->load_schema(<DATA>);
1;
# downloaded from https://xx-csa.bbcollab.com/documentation
__DATA__
{
  "type" : "object",
  "id" : "Attendee-collection",
  "properties" : {
      "limit" : {
      "type" : "integer"
      },
	  "name" : {
      "type" : "string"
      },
	  "offset" : {
      "type" : "integer"
      },
	  "fields" : {
      "type" : "string"
      },
	  "size" : {
      "type" : "integer"
      }
  }
}
