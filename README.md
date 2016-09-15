# NAME

Bb::Collaborate::Ultra - Perl 5 bindings to Collaborate Ultra Virtual Classroom Software

# SYNOPSIS
```
use Bb::Collaborate::Ultra::Connection;
use Bb::Collaborate::Ultra::Session;
use Bb::Collaborate::Ultra::User;
use Bb::Collaborate::Ultra::LaunchContext;

    my %credentials = (
      issuer => 'OUUK-REST-API12340ABCD',
      secret => 'ABCDEF0123456789AA',
      host => 'https://xx-csa.bbcollab.com',
    );

    # connect to server
    my $connection = Bb::Collaborate::Ultra::Connection->new(\%credentials);

    # create a virtual classroom, starts now runs, for 15 minutes
    my $start = time() + 60;
    my $end = $start + 900;
    my $session = Bb::Collaborate::Ultra::Session->post($connection, {
            name => 'Test Session',
            startTime => $start,
            endTime   => $end,
            },
        );

    # define a session user
    my $user = Bb::Collaborate::Ultra::User->new({
        extId => 'dwarring',
        displayName => 'David Warring',
        email => 'david.warring@gmail.com',
        firstName => 'David',
        lastName => 'Warring',
    });

    # register the user. obtain a join URL
    my $launch_context =  Bb::Collaborate::Ultra::LaunchContext->new({
          launchingRole => 'moderator',
          editingPermission => 'writer',
          user => $user,
         });
     my $url = $launch_context->join_session($session);

```

# DESCRIPTION

** UNDER CONSTRUCTION **