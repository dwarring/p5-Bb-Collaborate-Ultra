package Bb::Ultra::Connection {
    use warnings; use strict;
    use Crypt::JWT qw(encode_jwt decode_jwt);
    use JSON;
    use Moo;
    use REST::Client;
    use Bb::Ultra::Connection::Auth;
    use Bb::Ultra::Types;

    has 'issuer' => (is => 'rw', isa => Str, required => 1);
    has 'secret' => (is => 'rw', isa => Str, required => 1);
    has 'host'   => (is => 'rw', isa => Str, required => 1);

    has 'client' => (is => 'rw',  isa => class('REST::Client') );
    has 'auth'  =>  (is => 'rw', isa => class('Bb::Ultra::Connection::Auth') ); 
    has 'auth_start'  =>  (is => 'rw', isa => Int );
    has 'debug'  =>  (is => 'rw', isa => Int );

    sub auth_end {
	my $self = shift;
	my $auth = $self->auth
	    or return;

	$self->auth_start + $auth->expires_in;
    }

    sub response_data {
	my $self = shift;
	my $client = shift || $self->client;
	my $response_code = $client->responseCode;
	die "bad HTTP response code: $response_code"
	    unless $response_code == 200;
	my $json = $client->responseContent;
	warn "json:$json"
	    if $self->debug;
	from_json($json);
    }

    sub connect {
	my $self = shift;
	
	use constant JWT_TOKEN_ENDPOINT => 'token';
	use constant JWS_RSA_256 => 'HS256';
	use constant JWT_EXPIRY => 4 * 60; # 4 minutes

	my $client = $self->client( REST::Client->new );
	$client->setHost( $self->host);
  
	my $expiry = time()  +  JWT_EXPIRY;

	my $claims = {
	    iss => $self->issuer,
	    sub => $self->issuer,
	    exp => $expiry,
	};

	my $jwt = encode_jwt( payload => $claims, key => $self->secret, alg => JWS_RSA_256);
 
	my $query = $client->buildQuery({
	    grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
	    assertion => $jwt,
	});

	$self->auth_start( time() );
	$client->POST(JWT_TOKEN_ENDPOINT . $query, '', { 'Content-Type' => 'application/x-www-form-urlencoded' });
	my $auth_ref = $self->response_data($client);
	$self->auth(  Bb::Ultra::Connection::Auth->new($auth_ref) );
    }
}

1;
