use Class::Data::Inheritable;
package Bb::Ultra; BEGIN {
    use warnings; use strict;
    use Mouse;
    use parent qw{Class::Data::Inheritable};
    use JSON;
    use Bb::Ultra::Util;

    __PACKAGE__->mk_classdata('_types');
    __PACKAGE__->mk_classdata('resource');

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

    sub TO_JSON {
	my $self = shift;
	my $types = $self->_property_types;
	my $data = shift // {
	    map { $_ => $self->$_ }
	    grep { defined $self->$_ }
	    (keys %$types)
	    };

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
	$class->new($data);
    }

    sub load_schema {
	my $class = shift;
	my $data = join("", @_);
        my $schema = from_json($data);
	my $properties = $schema->{properties}
	    or die 'schema has no properties';

	foreach my $prop (sort keys %$properties) {
	    next if $class->meta->get_attribute($prop);
	    my $type = $properties->{$prop}{type}
	        or die "property has no type: $prop";
            my $isa = {string => 'Str',
		       boolean => 'Bool',
		       array  => 'Array',
		       object => 'Object',
	    }->{$type}
	        or die "unknown type: $type";
	    if ($type eq 'Array' || $type eq 'Object') {
		warn "ignoring $prop array/object";
		next;
	    }
	    my $format = $properties->{$prop}{format};
	    $isa = 'Date' if $format && $format eq 'DATE_TIME';
	    my $required = $properties->{$prop}{required} ? 1 : 0;
	    $class->meta->add_attribute(
		$prop => (isa => $isa, is => 'rw', required => $required)
		);
	}
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

}

1;
