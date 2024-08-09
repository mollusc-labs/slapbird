package Slapbird::Controller::Dashboard;

use Mojo::Base 'Mojolicious::Controller';
use Slapbird::Sanitizer::Application;
use Slapbird::Advice::ErrorAdvice;
use Data::ULID  qw(ulid);
use Time::HiRes qw(time);
use MIME::Base64;
use Try::Tiny;
use URL::Encode qw(url_decode_utf8);
use DateTime;

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

1;

