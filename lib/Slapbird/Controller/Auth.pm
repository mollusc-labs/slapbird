package Slapbird::Controller::Auth;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::UserAgent;
use Mojo::Promise;
use List::Util qw(first);
use Carp;
use Data::UUID;

sub logout {
  my $c = shift;
  if (not $c->logged_in) {
    return $c->redirect_to('/login');
  }
  $c->helpers->logout;
  return $c->redirect_to('/');
}

sub login {
  my $c        = shift;
  my $referrer = $c->param('referrer') // '/';

  if ($c->logged_in) {
    return $c->redirect_to('/dashboard');
  }

  $c->session(login_referrer => $referrer);
  return $c->render(template => 'auth/login');
}

# TODO: (RF) break this up
sub github {
  my $c    = shift;
  my $args = {
    redirect_uri => $ENV{GITHUB_REDIRECT_URI},
    scope        => 'user:email user repo'
  };

  if ($c->logged_in) {
    return $c->redirect_to('/dashboard');
  }

  return $c->oauth2->get_token_p(github => $args)->then(sub {
    return unless my $pr = shift;

    my $access_token = $pr->{access_token};
    $c->session(access_token => $access_token);

    my $github_info_request = $c->github_client->get_user_info($access_token);
    my $github_email_request
      = $c->github_client->get_user_emails($access_token);

    if (!$github_info_request->is_success || !$github_email_request->is_success)
    {
      $c->debug($github_info_request);
      $c->debug($github_email_request);
      Carp::croak(qq{Github might be down. Failed to reach API.});
    }

    my $email = (first { $_->{verified} && $_->{primary} }
        $github_email_request->json->@*)->{email};

    if (!$email) {
      $c->flash_failure('Your email must be verified with Github to log in.');
      $c->redirect_to('/login');
    }

    my $info = $github_info_request->json;

    # Create or select user
    my $user = $c->resultset('User')->find({email => $email});

    my $id = defined $user ? $user->user_id : undef;
    if (not $id) {
      $id = Data::UUID->new->create_str();

      my $guard = $c->dbic->txn_scope_guard;
      $c->resultset('User')->create({
        user_id        => $id,
        email          => $email,
        name           => $info->{login},
        oauth_id       => $info->{id},
        oauth_provider => 'GITHUB'
      });

      # If the user clicked an invite from another user.
      if (my $plan_to_join = $c->session('plan_to_join')) {
        my ($user_pricing_plan, $error)
          = $c->actions->associate_user_with_pricing_plan(
          user_id              => $id,
          user_pricing_plan_id => $plan_to_join
          );

        Carp::croak($error) if $error;
      }
      else {
        my ($user_pricing_plan, $error) = $c->actions->add_user_to_free_plan(
          schema  => $c->dbic,
          user_id => $id
        );

        Carp::croak($error) if $error;
      }


      $guard->commit;
    }

    if ($user) {
      $user->update({last_login => \'now()'});
    }
    else {
      $c->resultset('User')->find({user_id => $id})
        ->update({first_login => \'now()', last_login => \'now()'});
    }

    $c->session->{user_id} = $id;

    $c->flash_success('Welcome back ' . $c->user->name . '.');

    if ($c->session('login_referrer')) {
      return $c->redirect_to($c->session('login_referrer'));
    }

    $c->redirect_to('/dashboard');
  })->catch(sub {
    $c->debug(shift);
    $c->flash_danger('Something went wrong logging you in.');
    $c->redirect_to('/login');
  });
}


1;
