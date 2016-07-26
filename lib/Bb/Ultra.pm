package Bb::Ultra {
    use warnings; use strict;
    use Mouse;
    use JSON;

    sub freeze {
	my $self = shift;

	my %frozen;

	for my $att ($self->meta->get_attribute_list) {
	    my $val = $self->$att;
	    $frozen{$att} = $val if defined $val;
	}
	my $payload = to_json \%frozen;
	$payload;
    }

    sub thaw {
	my $self = shift;
	my $payload = shift;
	my $data = from_json($payload);
	my %atts = map {$_ => $_} ($self->meta->get_attribute_list);
	my %thawed;

	for my $fld (keys %$data) {
	    if (exists $atts{$fld}) {
		$thawed{$fld} = $data->{$fld};
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

}

1;
