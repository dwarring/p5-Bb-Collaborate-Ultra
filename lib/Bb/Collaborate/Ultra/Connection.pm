package Bb::Collaborate::Ultra::Connection {
    use warnings; use strict;
    use Bb::Collaborate::Ultra;
    use Crypt::JWT qw(encode_jwt decode_jwt);
    use JSON;
    use Mouse;
    use REST::Client;
    use Bb::Collaborate::Ultra::Connection::Auth;

    has 'issuer' => (is => 'rw', isa => 'Str', required => 1);
    has 'secret' => (is => 'rw', isa => 'Str', required => 1);
    has 'host'   => (is => 'rw', isa => 'Str', required => 1);

    has 'client' => (is => 'rw', isa => 'REST::Client' );
    has 'auth'  =>  (is => 'rw', isa => 'Bb::Collaborate::Ultra::Connection::Auth' ); 
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
	my $class = 'Bb::Collaborate::Ultra::Connection::Auth';
	$self->auth_start( time() );
	$client->POST($class->path . $query, '', { 'Content-Type' => 'application/x-www-form-urlencoded' });
	my $auth_msg = $self->response($client);
	$self->auth( $class->construct($auth_msg, connection => $self) );
    }

    sub post {
	my $self = shift;
	my $class = shift;
	my $data = shift;
	my %opt = @_;
	my $json = $class->freeze($data);
	my $path = $opt{path} // $class->path
            or die "no POST path";
	warn "POST: $path    $json" if $self->debug;
	$self->client->POST($path, $json, {
	    'Content-Type' => 'application/json',
	    'Authorization' => 'Bearer ' . $self->auth->access_token,
        },);
	$self->response;
    }

    sub put {
	my $self = shift;
	my $class = shift;
	my $data = shift;
	my %opt = @_;
	my $json = $class->freeze($data);
	my $path = $opt{path} // $class->path
            or die "no PUT path";
	warn "PUT: $path   $json" if $self->debug;
	$self->client->PUT($path, $json, {
	    'Content-Type' => 'application/json',
	    'Authorization' => 'Bearer ' . $self->auth->access_token,
        },);
	$self->response;
    }

    sub get {
	my $self = shift;
	my $class = shift;
	my $query_data = shift || {};
	my %opt = @_;

	my $path = $opt{path};
	$path //= $query_data->{id}
	        ? $class->resource . '/' . $query_data->{id}
	        : $class->resource;
	if (keys %$query_data) {
	    $path .= $self->client->buildQuery($class->TO_JSON($query_data));
	}
	warn "GET: $path" if ref($self) && $self->debug;
	$self->client->GET($path, {
	    'Content-Type' => 'application/json',
	    'Authorization' => 'Bearer ' . $self->auth->access_token,
        },);
	my $msg = from_json $self->response;
	$msg->{results}
	    ? map { $class->construct($_, connection => $self, parent => $opt{parent}) } @{ $msg->{results} }
	    : $class->construct($msg, connection => $self, parent => $opt{parent});
    }

    sub del {
	my $self = shift;
	my $class = shift;
	my $query_data = shift || {};

	my $path = $class->resource;
	die "id required for deletion"
	    unless $query_data->{id};
	$path .= '/' . $query_data->{id};
	
	warn "DELETE: $path" if $self->debug;
	$self->client->DELETE($path, {
	    'Content-Type' => 'application/json',
	    'Authorization' => 'Bearer ' . $self->auth->access_token,
        },);
	my $msg = $self->response;

    }

}

1;