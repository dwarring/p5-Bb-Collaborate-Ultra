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

Version 0.10

=cut

our $VERSION = '0.00.00_1';

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
has '_connection' => ('is' => 'rw'); sub connection { shift->_connection(@_)}
has '_parent' => ('is' => 'rw'); sub parent { shift->_parent(@_)}

our %enums;

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

sub freeze {
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
    my $data = shift // $self->_raw_data;

    my %frozen;

    for my $fld (keys %$data) {
	my $type = $prop_types->{$fld} // $param_types->{$fld} // do {
	    warn((ref($self) || $self).": unknown field/query-parameter: $fld");
	    'Str'
	};
	    
	my $val = $data->{$fld};
	$frozen{$fld} = Bb::Collaborate::Ultra::Util::freeze($val, $type);
    }
    \%frozen;
}

sub thaw {
    my $self = shift;
    my $data = shift;
    my $types = $self->_property_types;
    my %thawed;

    for my $fld (keys %$data) {
	if (exists $types->{$fld}) {
	    my $val = $data->{$fld};
	    $thawed{$fld} = Bb::Collaborate::Ultra::Util::thaw($val, $types->{$fld});
	}
	else {
	    warn "ignoring field: $fld";
	}
    }
    \%thawed;
}

sub construct {
    my $class = shift;
    my $payload = shift;
    my $data = $class->thaw($payload);
    my %opt = @_;
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
       $isa = $enums{$enum_name} //= Mouse::Util::TypeConstraints::enum( $enum_name, \@enum);
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

sub path {
    my $self = shift;
    my $path = '';
    $path .= $self->parent->path . '/'
	if ref($self) && $self->parent;
    $path .= $self->resource;
    my $id = ref $self && $self->id;
    $id ? $path . '/' . $id : $path;
}

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

sub post {
    my $class = shift;
    my $connection = shift || die "no connection";
    my $data = shift || die "no data";

    my $msg = $connection->post($class, $data, @_);
    $class->construct($msg, connection => $connection);
}

sub put {
    my $self = shift;
    my $connection = shift || $self->connection
	|| die "no connected";
    my $update_data = $self->_pending_updates;
    my $path = $self->path;
    my $msg = $connection->put(ref($self), $update_data, path => $path, @_);
    my $obj = $self->construct($msg, connection => $connection);
    if ($self) {
	$self->_db_data( $obj->_db_data );
	$obj->parent($self->parent);
    }
    $obj;
}

sub get {
    my $class = shift;
    my $connection = shift || die "no connection";
    my $query_data = shift || die "no data";

    $connection->get($class, $query_data, @_);
}

sub del {
    my $self = shift;
    my $connection = shift
	|| $self->connection
	|| die 'Not connected';
    my $class = ref $self;
    my $data = {id => $self->id};
    $connection->del($class, $data);
}

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
    my @recs = $connection->get($class => \%query);
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
