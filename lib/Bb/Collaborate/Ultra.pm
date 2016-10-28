use Class::Data::Inheritable;
package Bb::Collaborate::Ultra;
use warnings; use strict;
use Mouse;
use parent qw{Class::Data::Inheritable};
use JSON;
use Bb::Collaborate::Ultra::Util;
use Mouse::Util::TypeConstraints;
use Data::Compare;
use Clone;

=head1 NAME

Bb::Collaborate::Ultra - Perl bindings for Blackboard Ultra virtual classroms

=head1 VERSION

Version 0.00.00_3

=cut

our $VERSION = '0.00.00_3';

use 5.008003;

=head1 DESCRIPTION

Blackboard Collaborate Ultira is software for virtual web classrooms. It is
suitable for meetings, demonstrations web conferences, seminars, general
training and support.

Bb-Ultra is a set of Perl bindings and entity definitions for the
Collaborate REST services. These can be used to administer classrooms,
including sessions, users and recordings.

=cut
    
use 5.008003;

__PACKAGE__->mk_classdata('_types');
__PACKAGE__->mk_classdata('_db_data');
__PACKAGE__->mk_classdata('resource');
__PACKAGE__->mk_classdata('_query_params' => {
    limit => 'Int',
    offset => 'Int',
    fields => 'Str',
});
has '_connection' => ('is' => 'rw');
has '_parent' => ('is' => 'rw');

our %enums;

=pod

L<Bb::Collaborate::Ultra> is an abstract base class for various resource classess (e.g. L<Bb::Collaborate::Ultra::Session>) and contains both builder and inherited methods from implementing these classes.

=head1 METHODS

=cut
    
=head2 new

Creates a new object.

=cut
    
=head2 post

Saves a newly created object on the server.

=cut
    
sub post {
    my $class = shift;
    my $connection = shift || die "no connection";
    my $data = shift || die "no data";
    my %opt = @_;
    my $json = $class->_freeze($data);
    my $path = $opt{path} || $class->path
	or die "no POST path";

    my $msg = $connection->POST($path, $json, @_);
    $class->construct($msg, connection => $connection);
}

=head2 put

Updates an existing object

=cut

sub put {
    my $self = shift;
    my $connection = shift || $self->connection
	|| die "no connected";
    my $update_data = shift || $self->_pending_updates;
    my $class = ref($self) || $self;
    my $path = $self->path;
    my $json = $class->_freeze($update_data);
    my $msg = $connection->PUT($path, $json);
    my $obj = $self->construct($msg, connection => $connection);
    if ($self) {
	$self->_db_data( $obj->_db_data );
	$obj->parent($self->parent);
    }
    $obj;
}

=head2 get

Fetches one or more objects from the server.

=cut

sub get {
    my $self = shift;
    my $connection = shift || die "no connection";
    my $query_data = shift || die "no data";
    my %opt = @_;
    my $class = ref($self) || $self;

    my $path = $opt{path};
    $path ||= $query_data->{id}
	    ? $class->resource . '/' . $query_data->{id}
	    : $class->resource;
    if (keys %$query_data) {
	$path .= $connection->client->buildQuery($class->TO_JSON($query_data));
    }
    my $msg = $connection->GET($path);
    $msg->{results}
	? map { $class->construct($_, connection => $connection, parent => $opt{parent}) } @{ $msg->{results} }
	: $class->construct($msg, connection => $connection, parent => $opt{parent});
}

=head2 del

Deletes an object from the server

=cut

sub del {
    my $self = shift;
    my $connection = shift
	|| $self->connection
	|| die 'Not connected';
    my $data = shift || {id => $self->id};
    my $path = $self->resource;
    $connection->DEL($path, $data);
}

=head2 find_or_create

Attempts a C<get> on the object. If that fails, createas an new object on the server.

=cut

sub find_or_create {
    my $class = shift;
    my $connection = shift;
    my $data = shift;

    my $param_types = $class->query_params;
    my $prop_types = $class->_property_types;
    my %query;
    my %body;

    for my $fld (keys %$data) {
	my $val = $data->{$fld};
	if (exists $param_types->{$fld}) {
	    $query{$fld} = $val;
	}
	elsif (exists $prop_types->{$fld}) {
	    $body{$fld} = $val;
	}
	else {
	    warn "$class: ignoring unknown field: $fld";
	}
    }
    my @recs = $class->get($connection, \%query);
    my $rec;
    if (@recs) {
	warn "$class: ambiguous find_or_create query: @{[ keys %query ]}\n"
	    if @recs > 1;
	$rec = $recs[0];
	for (keys %body) {
	    $rec->$_($body{$_});
	}
    }
    else {
	$rec = $class->post($connection => $data);
    }
    $rec;
}

=head2 path

Computes a RESTful resource path for the object.

=cut

sub path {
    my $self = shift;
    my $path = '';
    $path .= $self->parent->path . '/'
	if ref($self) && $self->parent;
    $path .= $self->resource;
    my $id = ref $self && $self->id;
    $id ? $path . '/' . $id : $path;
}

=head2 parent

Returns any parent class for the object. May be used to compute the path.

=cut
    
 sub parent { shift->_parent(@_)}

=head2 changed

Returns a list of fields that have been updated since the
object was last saved via a `put`, or `post`, or fetched
via a `get`.

=cut

sub changed {
    my $self = shift;
    my $data = $self->_raw_data;
    my @changed;

    if (my $old_data = $self->_db_data) {
	# include only key and changed data
	for my $fld (sort keys %$data) {
	    # ignore time-stamps
	    next if $fld =~ /^(id|modified|created)$/;
	    my $new_val = $data->{$fld};
	    my $old_val = $old_data->{$fld};
	    push @changed, $fld
		    if !defined($old_val)
		    || !Compare($old_val, $new_val);
	}
    }
    @changed;
}

sub _pending_updates {
    my $self = shift;
    my $data = $self->_raw_data;
    my %pending;
    @pending{ $self->changed } = undef;
    # pass the primary key
    $pending{id} = undef; 
    ## seems we need to pass these!?
    $pending{startTime} = undef if $data->{startTime};
    $pending{endTime} = undef if $data->{endTime};
    my %updates = map { $_ => $data->{$_} } (sort keys %pending);
    \%updates;
}

=head2 connection

Returns the connection associated with the object. Will be set if
the object has been fetched via a `get`, added via a `store` or updated via a `put`.

=cut

sub connection { shift->_connection(@_)}


=head1 Internal METHODS

=cut
    
=head2 query_params

    __PACKAGE__->query_params(
        name => 'Str',
        extId => 'Str',
    );

This is used to specify any aditional layload fields that may be
passed as query parameters, or returned along with object data. 

=cut

sub query_params {
    my ($entity_class, %params) = @_;

    for (keys %params) {
	$entity_class->_query_params->{$_} = $params{$_};
    }

    return $entity_class->_query_params;
}

sub _property_types {
    my $class = shift;
    my $types = $class->_types;
    unless ($types) {
	my $meta = $class->meta;
	my @atts = grep { $_ !~ /^_/ } ($meta->get_attribute_list);

	$types = {
	    map {$_ => $meta->get_attribute($_)->{type_constraint}} @atts
	};
	$class->_types($types);
    }
    $types;
}

=head2 freeze

Serializes an object to JSON., with data conversion.

=over 4

=item Dates are converted from numeric unix timestamps to date-strings

=item Booleans are converted from numeric (0, 1) to 'true', or 'false'.

=item Nested objects are recursively serialized.

=back

=cut

sub _freeze {
    my $self = shift;
    my $frozen = $self->TO_JSON(@_);
    to_json $frozen, { convert_blessed => 1};
}

sub _raw_data {
    my $self = shift;
    my $types = $self->_property_types;
    my %data = (map { $_ => $self->$_ }
		grep { defined $self->$_ }
		(keys %$types));
    \%data;
}

sub TO_JSON {
    my $self = shift;
    my $prop_types = $self->_property_types;
    my $param_types = $self->query_params;
    my $data = shift || $self->_raw_data;

    my %frozen;

    for my $fld (keys %$data) {
	my $type = $prop_types->{$fld} || $param_types->{$fld} || do {
	    warn((ref($self) || $self).": unknown field/query-parameter: $fld");
	    'Str'
	};
	    
	my $val = $data->{$fld};
	$frozen{$fld} = Bb::Collaborate::Ultra::Util::_freeze($val, $type)
	    if defined $val;
    }
    \%frozen;
}

=head2 thaw

The reverse of `freeze`. Deserializes JSON data to objects, with conversion of dates, boolean values or nested objects.

=cut

sub _thaw {
    my $self = shift;
    my $data = shift;
    my $types = $self->_property_types;
    my %thawed;

    for my $fld (keys %$data) {
	if (exists $types->{$fld}) {
	    my $val = $data->{$fld};
	    $thawed{$fld} = Bb::Collaborate::Ultra::Util::_thaw($val, $types->{$fld})
		if defined $val;
	}
	else {
	    warn "ignoring field: $fld";
	}
    }
    \%thawed;
}

=head2 construct

Constructs a new object from server data.

=cut

sub construct {
    my $class = shift;
    my $payload = shift;
    my %opt = @_;
    my $data = $class->_thaw($payload);
    my $obj = $class->new($data);
    for ($opt{connection}) {
	$obj->connection($_) if $_
    }
    for ($opt{parent}) {
	$obj->parent($_) if $_;
    }
    # make a copy, so we can detect updates
    $obj->_db_data(Clone::clone $data);
    $obj;
}

=head2 load_schema

Constructs the object class from JSON schema data

=cut

sub load_schema {
    my $class = shift;
    my $data = join("", @_);
    my $schema = from_json($data);
    my $properties = $schema->{properties}
	or die 'schema has no properties';

    foreach my $prop (sort keys %$properties) {
	next if $class->meta->get_attribute($prop);
	my $prop_spec = $properties->{$prop};
	my $isa = $class->_build_isa( $prop, $prop_spec);
	my $required = $prop_spec->{required} ? 1 : 0;
	$class->meta->add_attribute(
	    $prop => (isa => $isa, is => 'rw', required => $required),
	    );
    }
}

sub _build_isa {
    my $class = shift;
    my $prop = shift;
    my $prop_spec = shift;
    my $isa;
    my $type = $prop_spec->{type}
       or die "property has no type: $prop";
    if ($type eq 'array') {
       my $of_type = $class->_build_isa($prop, $prop_spec->{items});
       $isa = 'ArrayRef[' . $of_type . ']';
    }
    elsif (my $enum = $prop_spec->{enum}) {
       my @enum = map { lc } (@$enum);
       # create an anonymous enumeration
       my $enum_name = 'enum_' . join('_', @enum);
       $isa = $enums{$enum_name} ||= Mouse::Util::TypeConstraints::enum( $enum_name, \@enum);
    }
    else {
       $isa = {string => 'Str',
               boolean => 'Bool',
               integer => 'Int',
               object => 'Object',
       }->{$type}
           or die "unknown type: $type";
       if ($isa eq 'Object' || $isa eq 'Array') {
           warn "unknown $prop object. Predeclare in $class?";
       }
    }
    my $format = $prop_spec->{format};
    $isa = 'Date' if $format && $format eq 'DATE_TIME';
    $isa;
}

#
# Shared subtypes
#
BEGIN {
    use Mouse::Util::TypeConstraints;

    subtype 'Date'
	=> as 'Num'
	=> where {m{^\d+(\.\d*)?$}}
	=> message {"invalid date: $_"};
}

=head1 LICENSE AND COPYRIGHT

Copyright 2016 David Warring.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
