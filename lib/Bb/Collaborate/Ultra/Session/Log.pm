package Bb::Collaborate::Ultra::Session::Log;
use warnings; use strict;
use Mouse;
use JSON;
extends 'Bb::Collaborate::Ultra::DAO';
use Mouse::Util::TypeConstraints;

=head1 NAME

Bb::Collaborate::Ultra::Session::Log

=head1 DESCRIPTION

Session logging sub-record.

=head1 METHODS

See L<https://xx-csa.bbcollab.com/documentation#Session>

=cut
    
coerce __PACKAGE__, from 'HashRef' => via {
    __PACKAGE__->new( $_ )
};
 
__PACKAGE__->resource('instances');
__PACKAGE__->load_schema(<DATA>);

sub attendance {
    my $self = shift;
    my $connection = shift || $self->connection;
    my $path = $self->path.'/attendees';
    require Bb::Collaborate::Ultra::Session::Log::Attendee;
    Bb::Collaborate::Ultra::Session::Log::Attendee->get($connection => {}, path => $path, parent => $self);
}

# **NOT DOCUMENTED** in https://xx-csa.bbcollab.com/documentation
# schema has been reversed engineered
1;
__DATA__
{
    "type" : "object",
    "id" : "SessionLog",
    "properties" : {
        "id" : {
            "type" : "string"
        },
        "opened" : {
            "type" : "string",
            "format" : "DATE_TIME"
        },
        "closed" : {
            "type" : "string",
            "format" : "DATE_TIME"
        }
    }
}
