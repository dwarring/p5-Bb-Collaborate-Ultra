package t::Ultra;
use warnings; use strict;

sub test_connection {
    my $class = shift;
    my %opt = @_;

    my $suffix = $opt{suffix} || '';
    my %result;

    my $issuer = $ENV{'BB_ULTRA_ISSUER'};
    my $secret = $ENV{'BB_ULTRA_SECRET'};
    my $host   = $ENV{'BB_ULTRA_HOST'};

    if ($issuer && $secret && $host) {
	my %params = (
	    issuer => $issuer, secret => $secret, host => $host,
	    );
	my $connection =  Bb::Ultra::Connection->new(\%params);
	$connection->debug(  $ENV{'BB_ULTRA_DEBUG'} );
	$params{connection} = $connection;
	return %params
    }
    else {
	return (
	    skip => 'Please set BB_ULTRA_{ISSUER|SECRET|URL}',
	)
    }
}


1;
