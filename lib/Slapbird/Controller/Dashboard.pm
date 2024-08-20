package Slapbird::Controller::Dashboard;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Cookie::Response;
use Slapbird::Sanitizer::Application;
use Slapbird::Advice::ErrorAdvice;
use Data::ULID  qw(ulid);
use Time::HiRes qw(time);
use MIME::Base64;
use Try::Tiny;
use URL::Encode qw(url_decode_utf8);
use DateTime;
use Crypt::JWT qw(encode_jwt decode_jwt);

sub dashboard {
  my ($c) = @_;

  my $user_pricing_plan  = $c->user->user_pricing_plan;
  my $pricing_plan       = $user_pricing_plan->pricing_plan;
  my $user_is_associated = $c->user->is_associated;

  if (!(scalar $user_pricing_plan->applications->all)) {
    return $c->redirect_to('/dashboard/new-app');
  }

  my $requests_today
    = $c->application_context
    ? $c->cache->get($c->application_context->application_id)
    : 0;

  return $c->render(
    template           => 'dashboard',
    pricing_plan       => $pricing_plan,
    user_is_associated => $user_is_associated,
    requests_today     => $requests_today
  );
}

sub transaction_summary {
  my ($c) = @_;

  my ($from, $to) = $c->get_from_to_time();
  my $page            = $c->param('page') ? $c->param('page') : 1;
  my $endpoint_base64 = $c->param('endpoint');
  my $code            = $c->param('code');
  my $size            = 10;

  my ($pager, $transactions) = $c->actions->get_transaction_summaries(
    to             => $to,
    from           => $from,
    end_point      => decode_base64($endpoint_base64),
    code           => $code,
    page           => $page,
    size           => $size,
    application_id => $c->application_context->application_id
  );

  my $appendable_href
    = '/dashboard/transaction-summary/'
    . $endpoint_base64
    . '?from='
    . $from . '&to='
    . $to;

  return $c->render(
    template        => 'dashboard_transaction_summary',
    pager           => $pager,
    transactions    => $transactions,
    appendable_href => $appendable_href,
    end_point       => decode_base64($endpoint_base64),
    return_href     =>
      encode_base64($appendable_href . '&page=' . $pager->current_page)
  );
}

sub transaction {
  my ($c) = @_;

  my $transaction_id = $c->param('transaction_id');
  my $return_uri     = decode_base64($c->param('return_href'));

  my $transaction;
  my $error;

  try {
    $transaction = $c->resultset('HTTPTransaction')->find({
      http_transaction_id => $transaction_id,
      application_id      => $c->application_context->application_id
    });
  }
  catch {
    $error = $_;
  };

  if ($error) {
    $c->log->error($error);
    return $c->render(template => 'util/bad_request', status => 400);
  }

  if (!$transaction) {
    return $c->render(template => 'util/not_found', status => 404);
  }

  return $c->render(
    template    => 'dashboard_transaction',
    return_href => $return_uri,
    transaction => $transaction
  );
}

sub my_apps {
  my ($c) = @_;

  my $pricing_plan = $c->user->user_pricing_plan->pricing_plan;
  my @applications = $c->user->user_pricing_plan->applications;

  return $c->render(
    template     => 'my_apps',
    pricing_plan => $pricing_plan,
    applications => \@applications
  );
}

sub new_app {
  my ($c) = @_;

  return $c->render(template => 'new_app');
}

sub manage_application {
  my ($c) = @_;

  my $user              = $c->user;
  my $user_pricing_plan = $user->user_pricing_plan;
  my $is_associated     = $user->is_associated;
  my $application       = $c->application_context;
  my $can_edit = ($application->user_id eq $user->user_id) || !$is_associated;

  return $c->render(
    template    => 'dashboard_manage_application',
    application => $application,
    can_edit    => $can_edit
  );
}

sub new_api_key {
  my ($c) = @_;

  my $user              = $c->user;
  my $application       = $c->application_context;
  my $user_pricing_plan = $user->user_pricing_plan;
  my $api_key_name      = url_decode_utf8($c->param('name'));

  if (!$api_key_name || length($api_key_name) > 100) {
    return $c->render(template => 'util/bad_request', status => 400);
  }

  if (scalar($application->api_keys->all) == 10) {
    $c->flash_danger("An application is allowed a maximum of 10 api keys.");
    return $c->redirect_to('/dashboard/manage-application');
  }

  $c->actions->create_api_key(
    user_id          => $user->user_id,
    application_id   => $application->application_id,
    application_slug => $application->slug,
    api_key_name     => $api_key_name,
  );

  return $c->redirect_to('/dashboard/manage-application');
}

sub delete_api_key {
  my ($c) = @_;

  my $user        = $c->user;
  my $application = $c->application_context;
  my $api_key_id  = $c->param('api_key_id');

  for my $api_key ($application->api_keys->all) {
    if ($api_key->api_key_id eq $api_key_id) {
      if ($api_key->user_id ne $user->user_id && $user->is_associated) {
        return $c->render(template => 'util/unauthorized', status => 400);
      }
      $c->actions->delete_api_key(api_key_id => $api_key_id);
      return $c->redirect_to('/dashboard/manage-application');
    }
  }

  return $c->render(template => 'util/bad_request', status => 400);
}

# TODO: (RF) This needs to be refactored to the new actions API.
sub create_new_app {
  my ($c) = @_;

  chomp(my $name        = $c->req->json->{name});
  chomp(my $type        = $c->req->json->{type});
  chomp(my $description = $c->req->json->{description});
  my $user              = $c->user;
  my $user_pricing_plan = $user->user_pricing_plan;
  my $num_applications  = scalar $user_pricing_plan->applications->all;

  return $c->render(
    status => 400,
    json   => [{
      message =>
        q{You've maxxed out the number of applications allowed on your plan.}
    }]
    )
    if $num_applications == $user_pricing_plan->pricing_plan->max_applications;

  my ($json, $errors)
    = Slapbird::Sanitizer::Application->sanitize(
    {name => $name, type => $type});

  if ($errors) {
    return $c->render(
      status => 400,
      json   =>
        Slapbird::Advice::ErrorAdvice->new(errors => $errors)->to_hashref()
    );
  }

  my $guard = $c->dbic->txn_scope_guard;

  my ($application, $application_error) = $c->actions->create_application(
    application_name        => $json->{name},
    application_description => $json->{description} // '',
    user_pricing_plan_id    => $user_pricing_plan->user_pricing_plan_id,
    user_id                 => $user->user_id,
  );

  if ($application_error) {
    return $c->render(
      status => 500,
      json   => Slapbird::Advice::ErrorAdvice->new(
        errors => {error => ['Something went wrong creating your application.']}
      )
    );
  }

  my ($api_key, $api_key_error) = $c->actions->create_api_key(
    application_id   => $application->application_id,
    application_slug => $application->slug,
    user_id          => $user->user_id,
    api_key_name     => 'Default',
  );

  if ($api_key_error) {
    return $c->render(
      status => 500,
      json   => Slapbird::Advice::ErrorAdvice->new(
        errors => {error => ['Something went wrong creating your application.']}
      )
    );
  }

  $guard->commit;

  return $c->render(
    status => 201,
    json   => {
      api_key        => $api_key->application_api_key,
      application_id => $application->application_id
    }
  );
}

sub confirm_delete_app {
  my ($c) = @_;
  return $c->render(template => 'dashboard_confirm_delete_application');
}

sub delete_app {
  my ($c) = @_;

  # Context is cleared on next request. If they have no apps,
  # they'll end up on /dashboard/new-app.
  my $app_name = $c->application_context->name;
  $c->actions->delete_application(
    application_id => $c->application_context->application_id);

  $c->flash_success($app_name . ' was deleted successfully.');

  return $c->redirect_to('/dashboard');
}

sub manage_plan {
  my ($c) = @_;

  my $invitation_link = $c->actions->create_invitation_link(
    user_pricing_plan_id => $c->user->user_pricing_plan->user_pricing_plan_id,
    secure_key           => $c->secure_key
  );

  my $card = $c->user->user_pricing_plan->card;
  my $user = $c->user;

  return $c->render(
    template           => 'dashboard_manage_plan',
    user_id            => $user->user_id,
    user_pricing_plan  => $user->user_pricing_plan,
    pricing_plan       => $user->user_pricing_plan->pricing_plan,
    invitation_link    => $invitation_link,
    user_is_associated => $user->is_associated,
    card               => $card
  );
}

sub confirm_join_plan {
  my ($c) = @_;

  return $c->redirect_to('/dashboard') unless $c->session('plan_to_join');

  my $user_pricing_plan = $c->resultset('UserPricingPlan')
    ->find({user_pricing_plan_id => $c->session('plan_to_join')});

  if (!$user_pricing_plan) {
    $c->session(plan_to_join => undef);
    return $c->redirect_to('/dashboard');
  }

  return $c->render(
    template          => 'dashboard_confirm_join_plan',
    user_pricing_plan => $user_pricing_plan,
    pricing_plan      => $user_pricing_plan->pricing_plan
  );
}

sub join_plan {
  my ($c) = @_;

  my $user_pricing_plan_id = $c->session('plan_to_join');
  return $c->redirect_to('/dashboard') if !$user_pricing_plan_id;

  $c->session(plan_to_join => undef);

  my $guard = $c->dbic->txn_scope_guard;

  my $error;
  (undef, $error) = do {
    if ($c->user->is_associated) {
      $c->actions->delete_associated_user_pricing_plan(
        associated_user_pricing_plan_id =>
          $c->user->associated_user_pricing_plan
          ->associated_user_pricing_plan_id);
    }
    else {
      $c->actions->delete_user_pricing_plan(user_pricing_plan_id =>
          $c->user->user_pricing_plan->user_pricing_plan_id);
    }
  };

  goto ERROR if $error;

  my $associated_user_pricing_plan;
  ($associated_user_pricing_plan, $error)
    = $c->actions->associate_user_with_pricing_plan(
    user_id              => $c->user->user_id,
    user_pricing_plan_id => $user_pricing_plan_id
    );

ERROR:
  if ($error) {
    $c->log->error($error);
    $c->flash_danger(
      'Something went wrong joining that plan... Please try again later.');
    return $c->redirect_to('/dashboard');
  }

  $guard->commit;

  $c->flash_success("You've successfully joined "
      . $associated_user_pricing_plan->user_pricing_plan->user->name . "'s "
      . $associated_user_pricing_plan->user_pricing_plan->pricing_plan->name
      . ' plan!');

  return $c->redirect_to('/dashboard');
}

sub confirm_leave_plan {
  my ($c) = @_;

  if (!$c->user->is_associated) {
    return $c->redirect_to('/dashboard');
  }

  $c->render(
    template          => 'dashboard_confirm_leave_plan',
    user_pricing_plan => $c->user->user_pricing_plan,
    pricing_plan      => $c->user->user_pricing_plan->pricing_plan
  );
}

sub leave_plan {
  my ($c) = @_;

  if (!$c->user->is_associated) {
    return $c->redirect_to('/dashboard');
  }

  my $scope_guard = $c->dbic->txn_scope_guard;

  my (undef, $error)
    = $c->actions->delete_associated_user_pricing_plan(
    associated_user_pricing_plan_id =>
      $c->user->associated_user_pricing_plan->associated_user_pricing_plan_id);

  goto ERROR if $error;

  my $user_pricing_plan;
  ($user_pricing_plan, $error)
    = $c->actions->add_user_to_free_plan(user_id => $c->user->user_id);

ERROR:
  if ($error) {
    $c->log->error($error);
    $c->flash_danger(
      'Something went wrong leaving your plan... Please try again later.');
    return $c->redirect_to('/dashboard');
  }

  $scope_guard->commit();

  $c->cookie(application_context => '', {expires => 1});

  return $c->redirect_to('/dashboard/new-app');
}

sub confirm_remove_user {
  my ($c) = @_;

  if ($c->user->is_associated) {
    return $c->redirect_to('/dashboard');
  }

  my $user_id = $c->param('user_id');
  my $user_to_remove;
  for ($c->user->user_pricing_plan->associated_user_pricing_plans) {
    if ($_->user_id eq $user_id) {
      $user_to_remove = $_->user;
    }
  }

  my $error;
  if (!$user_to_remove) {
    $error = 'User does not exist on plan.';
  }

  if ($error) {
    $c->log->error($error);
    $c->flash_danger(
      'Something went wrong removing a user from your plan... Please try again later.'
    );
    return $c->redirect_to('/dashboard/manage-plan');
  }


  return $c->render(
    template       => 'dashboard_confirm_remove_user',
    user_to_remove => $user_to_remove
  );
}

sub remove_user {
  my ($c) = @_;

  if ($c->user->is_associated) {
    return $c->redirect_to('/dashboard');
  }

  my $scope_guard = $c->dbic->txn_scope_guard;

  my $user_id = $c->param('user_id');
  my $user_to_remove;
  for ($c->user->user_pricing_plan->associated_user_pricing_plans) {
    if ($_->user_id eq $user_id) {
      $user_to_remove = $_->user;
    }
  }

  my $error;
  if (!$user_to_remove) {
    $error = 'User does not exist on plan.';
  }

  (undef, $error) = $c->actions->transfer_applications_from_user_to_user(
    from_user_id => $user_to_remove->user_id,
    to_user_id   => $c->user->user_pricing_plan->user_id
  );

  goto ERROR if $error;

  (undef, $error)
    = $c->actions->delete_associated_user_pricing_plan(
    associated_user_pricing_plan_id =>
      $user_to_remove->associated_user_pricing_plan
      ->associated_user_pricing_plan_id);

  goto ERROR if $error;

  my $user_pricing_plan;
  ($user_pricing_plan, $error)
    = $c->actions->add_user_to_free_plan(user_id => $user_to_remove->user_id);

ERROR:
  if ($error) {
    $c->log->error($error);
    $c->flash_danger(
      'Something went wrong removing a user from your plan... Please try again later.'
    );
    return $c->redirect_to('/dashboard/manage-plan');
  }

  $scope_guard->commit();

  return $c->redirect_to('/dashboard/manage-plan');
}

1;
