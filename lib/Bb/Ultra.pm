package Bb::Ultra {
    use warnings; use strict;
    use Mouse;
    use JSON;
    use Bb::Ultra::Util;

=head2 property_types

   my $user_types = MyApp::Entity::User->property_types;
   my $type_info = Elive::Util::inspect_type($user_types->{role})

Return a hashref of attribute data types.

=cut

    sub _property_types {
	my $class = shift;
	my $meta = $class->meta;
	my @atts = $meta->get_attribute_list;

	return {
	    map {$_ => $meta->get_attribute($_)->{type_constraint}} @atts
	};
    }

    sub freeze {
	my $self = shift;

	my %frozen;
	my $types = $self->_property_types;

	for my $att (sort keys %$types) {
	    my $val = $self->$att;
	    $frozen{$att} = Bb::Ultra::Util::freeze($val, $types->{$att})
		if defined $val;
	}
	my $payload = to_json \%frozen;
	$payload;
    }

    sub thaw {
	my $self = shift;
	my $payload = shift;
	my $data = from_json($payload);
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
