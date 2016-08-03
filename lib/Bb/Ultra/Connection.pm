package Bb::Ultra::Connection {
    use warnings; use strict;
    use Bb::Ultra;
    use Crypt::JWT qw(encode_jwt decode_jwt);
    use JSON;
    use Mouse;
    use REST::Client;
    use Bb::Ultra::Connection::Auth;

    has 'issuer' => (is => 'rw', isa => 'Str', required => 1);
    has 'secret' => (is => 'rw', isa => 'Str', required => 1);
    has 'host'   => (is => 'rw', isa => 'Str', required => 1);

    has 'client' => (is => 'rw', isa => 'REST::Client' );
    has 'auth'  =>  (is => 'rw', isa => 'Bb::Ultra::Connection::Auth' ); 
    has 'auth_start'  =>  (is => 'rw', isa => 'Int' );
    has 'debug'  =>  (is => 'rw', isa => 'Int' );

    sub auth_end {
	my $self = shift;
	my $auth = $self->auth
	    or return;

	$self->auth_start + $auth->expires_in;
    }

    sub response {
	my $self = shift;
	my $client = shift || $self->client;
	warn "response: ". $client->responseContent
	    if $self->debug;
	my $response_code = $client->responseCode;
	die "bad HTTP response code: $response_code"
	    unless $response_code == 200;
	$client->responseContent;
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
	my $auth_msg = $self->response($client);
	$self->auth(  Bb::Ultra::Connection::Auth->construct($auth_msg) );
    }

    sub put {
	my $self = shift;
	my $class = shift;
	my $data = shift;
	my %opt = @_;
	my $json = $class->freeze($data);
	my $path = $opt{path} // $class->resource;
	$self->client->POST($path, $json, {
	    'Content-Type' => 'application/json',
	    'Authorization' => 'Bearer ' . $self->auth->access_token,
        },);
	$self->response;
    }

    sub get {
	my $self = shift;
	my $class = shift;
	my $data = shift || {};
	my %opt = @_;

	my $path = $opt{path};
	$path //= $data->{id}
	        ? $class->resource . '/' . $data->{id}
	        : $class->resource;
	
	$self->client->GET($path, {
	    'Content-Type' => 'application/json',
	    'Authorization' => 'Bearer ' . $self->auth->access_token,
        },);
	my $msg = from_json $self->response;
	$msg->{results}
	    ? map { $class->construct($_) } @{ $msg->{results} }
	    : $class->construct($msg);
    }

    sub del {
	my $self = shift;
	my $class = shift;
	my $data = shift || {};

	my $path = $class->resource;
	die "path required for `deletion"
	    unless $data->{id};
	$path .= '/' . $data->{id};
	
	$self->client->DELETE($path, {
	    'Content-Type' => 'application/json',
	    'Authorization' => 'Bearer ' . $self->auth->access_token,
        },);
	my $msg = $self->response;

    }

}

1;
