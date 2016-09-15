package Bb::Collaborate::Ultra::Connection;
use warnings; use strict;
use Bb::Collaborate::Ultra;
use Crypt::JWT qw(encode_jwt decode_jwt);
use JSON;
use Mouse;
use REST::Client;
use Try::Tiny;
use Bb::Collaborate::Ultra::Connection::Auth;

has 'issuer' => (is => 'rw', isa => 'Str', required => 1);
has 'secret' => (is => 'rw', isa => 'Str', required => 1);
has 'host'   => (is => 'rw', isa => 'Str', required => 1);

has '_client' => (is => 'rw', isa => 'REST::Client' );
has 'auth'  =>  (is => 'rw', isa => 'Bb::Collaborate::Ultra::Connection::Auth' ); 
has 'debug'  =>  (is => 'rw', isa => 'Int' );

sub _response {
    my $self = shift;
    my $client = shift || $self->client;
    my $response_content = $client->responseContent;
    my $response_code = $client->responseCode;
    warn "RESPONSE: [$response_code] ". $response_content. "\n\n"
	if $self->debug;
    my $response_data;
    if ($response_content) {
	try {
	    $response_data = from_json( $response_content);
	}
	catch {
	    die "[$response_code] $response_content";
	};

	die "[$response_code] $response_data->{errorKey} : $response_data->{errorMessage}\n"
	    if $response_data->{errorKey};
    }
    die "bad HTTP response code: $response_code"
	unless $response_code == 200;
    $response_data;
}

use constant JWS_RSA_256 => 'HS256';
use constant JWT_EXPIRY => 4 * 60; # 4 minutes

sub client {
    my $self = shift;
    my $client = $self->_client;
    unless ($client) {
	$client= REST::Client->new;
	$client->setHost( $self->host);
	$self->_client($client);
    }
    $client;
}

sub renew_lease {
    my $self = shift;
    my $expiry = shift || time()  +  JWT_EXPIRY;
    my $class = 'Bb::Collaborate::Ultra::Connection::Auth';
    my $client = $self->client;

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

    my $path = $class->path;
    warn "POST: $path$query\n" if $self->debug;
    $client->POST($path . $query, '', { 'Content-Type' => 'application/x-www-form-urlencoded' });
    my $auth_msg = $self->_response($client);
    my $auth = $class->construct($auth_msg, connection => $self);
    $auth->_leased( time() );
    $self->auth( $auth );
}

sub connect {
    my $self = shift;

    my $client = $self->client;

    $self->renew_lease
	unless ($self->auth);
}

sub post {
    my $self = shift;
    my $path = shift;
    my $json = shift;
    warn "POST: $path    $json\n" if $self->debug;
    $self->client->POST($path, $json, {
	'Content-Type' => 'application/json',
	'Authorization' => 'Bearer ' . $self->auth->access_token,
    },);
    $self->_response;
}

sub put {
    my $self = shift;
    my $path = shift;
    my $json = shift;
    warn "PUT: $path   $json\n" if $self->debug;
    $self->client->PUT($path, $json, {
	'Content-Type' => 'application/json',
	'Authorization' => 'Bearer ' . $self->auth->access_token,
    },);
    $self->_response;
}

sub get {
    my $self = shift;
    my $path = shift;
    warn "GET: $path\n" if $self->debug;
    $self->client->GET($path, {
	'Content-Type' => 'application/json',
	'Authorization' => 'Bearer ' . $self->auth->access_token,
    },);
    $self->_response;
}

sub del {
    my $self = shift;
    my $path = shift;
    my $query_data = shift || {};

    die "id required for deletion"
	unless $query_data->{id};
    $path .= '/' . $query_data->{id};

    warn "DELETE: $path\n" if $self->debug;
    $self->client->DELETE($path, {
	'Content-Type' => 'application/json',
	'Authorization' => 'Bearer ' . $self->auth->access_token,
    },);
    $self->_response;
}

1;
