package Bb::Collaborate::Ultra::Session::Occurrence;
 use warnings; use strict;
 use Mouse;
 use JSON;
 extends 'Bb::Collaborate::Ultra';
use Mouse::Util::TypeConstraints;
coerce __PACKAGE__, from 'HashRef' => via {
    __PACKAGE__->new( $_ )
};
 
__PACKAGE__->load_schema(<DATA>);
# downloaded from https://xx-csa.bbcollab.com/documentation
1;
__DATA__
{
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
