use Class::Data::Inheritable;
package Bb::Ultra;
use warnings; use strict;
use Mouse;
use parent qw{Class::Data::Inheritable Class::Accessor};
use JSON;
use Bb::Ultra::Util;
use Mouse::Util::TypeConstraints;
use Data::Compare;
use Clone;

=head1 NAME

Bb::Ultra - Perl bindings for Blackboard Ultra virtual classroms

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
__PACKAGE__->mk_accessors('connection');
__PACKAGE__->mk_accessors('parent');

our %enums;

=head2 property_types

my $user_types = MyApp::Entity::User->property_types;
my $type_info = Elive::Util::inspect_type($user_types->{role})

Return a hashref of attribute data types.

=cut

sub _property_types {
    my $class = shift;
    my $types = $class->_types;
    unless ($types) {
	my $meta = $class->meta;
	my @atts = $meta->get_attribute_list;

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
    my $types = $self->_property_types;
    my $data = shift // $self->_raw_data;

    my %frozen;

    for my $fld (keys %$data) {
	if (exists $types->{$fld}) {
	    my $val = $data->{$fld};
	    $frozen{$fld} = Bb::Ultra::Util::freeze($val, $types->{$fld});
	}
	else {
	    warn "ignoring field: $fld";
	}
    }
    \%frozen;
}

sub thaw {
    my $self = shift;
    my $payload = shift;
    my $data = ref $payload
	? $payload
	: from_json($payload);
    my $types = $self->_property_types;
    my %thawed;

    for my $fld (keys %$data) {
	if (exists $types->{$fld}) {
	    my $val = $data->{$fld};
	    $thawed{$fld} = Bb::Ultra::Util::thaw($val, $types->{$fld});
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

sub load_schema {
    my $class = shift;
    my $data = join("", @_);
    my $schema = from_json($data);
    my $properties = $schema->{properties}
	or die 'schema has no properties';

    foreach my $prop (sort keys %$properties) {
	next if $class->meta->get_attribute($prop);
	my $isa;
	if (my $enum = $properties->{$prop}{enum}) {
	    my @enum = map { lc } (@$enum);
	    # create an anonymous enumeration
	    my $enum_name = 'enum(' . join('|', @enum) . ')';
	    $isa = $enums{$enum_name} //= Mouse::Util::TypeConstraints::enum( $enum_name, \@enum);
	}
	else {
	    my $type = $properties->{$prop}{type}
	    or die "property has no type: $prop";
	    $isa = {string => 'Str',
		    boolean => 'Bool',
		    array  => 'Array',
		    object => 'Object',
	    }->{$type}
		or die "unknown type: $type";
	    if ($type eq 'Array' || $type eq 'Object') {
		warn "ignoring $prop array/object. Predeclare in $class?";
		next;
	    }
	}
	my $format = $properties->{$prop}{format};
	$isa = 'Date' if $format && $format eq 'DATE_TIME';
	my $required = $properties->{$prop}{required} ? 1 : 0;
	$class->meta->add_attribute(
	    $prop => (isa => $isa, is => 'rw', required => $required)
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

sub _pending_updates {
    my $self = shift;
    my $data = $self->_raw_data;
    if (my $old_data = $self->_db_data) {
	# include only key and changed data
	for my $fld (sort keys %$data) {
	    # ignore time-stamps
	    my $new_val = $data->{$fld};
	    my $old_val = $old_data->{$fld};
	    my $keep;
	    unless ($fld eq 'modified' || $fld eq 'created') {
		$keep = $fld eq 'id'
		    ## seems we need to pass these!?
		    || $fld eq 'startTime' || $fld eq 'endTime'
		    || !defined($old_val)
		    || !Compare($old_val, $new_val);
	    }
	    delete $data->{$fld}
		unless $keep;
	}
    }
    $data;
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
    my $connection = $self->connection
	|| die "no connected";
    my $data = $self->TO_JSON($self->_pending_updates);
    my $path = $self->path;
    my $msg = $connection->put(ref($self), $data, path => $path, @_);
    my $obj = $self->construct($msg, connection => $connection);
    if ($self) {
	$self->_db_data( $obj->_db_data );
	$obj->parent($self->parent);
    }
    $obj;
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

Copyright 2012-2015 David Warring.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
