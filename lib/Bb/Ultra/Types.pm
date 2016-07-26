package Bb::Ultra::Types {
    use warnings; use strict;
    use MooX::Types::MooseLike::Base qw(:all);

    sub class {
	my $type = shift;
	sub { $_[0]->isa($type) }
    }

    our (@ISA, @EXPORT, %EXPORT_TAGS);
    BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw<Int Str Bool class>;
	%EXPORT_TAGS = (all => \@EXPORT);
    }
}
1;
