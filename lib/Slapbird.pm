# This file is apart of SlapbirdAPM, a Free and Open-Source
# web application APM for Perl 5 web applications.
#
# Copyright (C) 2024  Mollusc Labs.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


package Slapbird;

use Mojo::Base 'Mojolicious';
use Mojo::Log;
use Mojo::Pg;
use Mojo::IOLoop;
use Mojo::File;
use Cache::Memcached::Fast;
use Carp ();
use Const::Fast;
use Data::Printer;
use Slapbird::Client::Github;
use Slapbird::Schema;
use Slapbird::Mojolicious::Sessions;
use Slapbird::Actions;
use Slapbird::Util qw(slugify);
use Time::HiRes    qw(time);
use Try::Tiny;
use Net::Stripe::Simple;
use namespace::clean;

our $VERSION = 0.001;

$Carp::Verbose = 1;

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

sub startup {
  my ($self) = @_;

  $ENV{SLAPBIRD_PRODUCTION} = 1 if $self->mode eq 'production';

  $self->sessions(
    Slapbird::Mojolicious::Sessions->new((
      $ENV{SLAPBIRD_PRODUCTION} ? (secure => 1) : (secure => 0))));

  my $database_uri = $ENV{DATABASE_URI};

  Carp::croak('No DATABASE_URI set, cannot start application.')
    unless defined $database_uri;

  $self->app->static->classes(['Slapbird::Controller::Static']);
  push @{$self->app->static->paths}, $self->app->home->child('public');

  $self->plugin('DefaultHelpers');
  $self->plugin('TagHelpers');
  $self->plugin(
    'OAuth2' => {
      providers =>
        {github => {key => $ENV{GITHUB_APP_ID}, secret => $ENV{GITHUB_SECRET}}}
    }
  );
  $self->plugin(

    # Every hour
    'Cron' => (
      thirty_day_clear => {
        base    => 'utc',
        crontab => '0 * * * *',
        code    => sub {
          const my $THIRTY_DAYS_MS => 2_592_000_000;

          my (undef, $app) = @_;

          $app->log->info(
            'Doing hourly check to clear +30 day http_transactions');

          my $rs
            = $app->resultset('HTTPTransaction')
            ->search(
            {start_time => {-between => [0, (time * 1_000) - $THIRTY_DAYS_MS]}}
            );

          $app->log->info(
            'Deleting ' . $rs->count . ' HTTP transactions from 30 days ago.');

          $rs->delete();
        }
      },
      set_plans_on_hold => {
        base    => 'utc',
        crontab => '0 * * * *',
        code    => sub {
          my (undef, $app) = @_;

          use Slapbird::Client::Stripe;
          my $stripe_client = Slapbird::Client::Stripe->new();

          $app->log->info('Doing hourly subscription check');

          try {
            my @user_pricing_plans = $app->resultset('UserPricingPlan')
              ->search({stripe_id => +{-not => undef}})->all;

            for my $user_pricing_plan (@user_pricing_plans) {
              next if $user_pricing_plan->on_hold;

              my $subscription_response = $stripe_client->list_subscriptions({
                customer => $user_pricing_plan->user->stripe_id,
                status   => 'ended'
              })->result;

              if (!$subscription_response->is_success) {
                Carp::croak('Got a bad response from Stripe '
                    . $subscription_response->body);
              }

              my @stripe_subscriptions
                = @{$subscription_response->json->{data}};
              my %stripe_subscription_lookup
                = map { $_->{id} => $_ } @stripe_subscriptions;

              my $stripe_subscription
                = $stripe_subscription_lookup{$user_pricing_plan->stripe_id};

              next unless $stripe_subscription;

              $user_pricing_plan->update({on_hold => 1});
            }
          }
          catch {
            $app->log->error("Error when checking plans to set on hold: $_");
            return;
          };
        }
      }
    )
  );

  $self->helper(
    dbh => sub {
      state $pg = Mojo::Pg->new($database_uri);
    }
  );
  $self->helper(db => sub { shift->dbh->db() });
  $self->helper(
    dbic => sub {
      my $dbh = shift->db->dbh;
      Slapbird::Schema->connect(sub {$dbh});
    }
  );
  $self->helper(
    resultset => sub {
      return shift->dbic->resultset(@_);
    }
  );
  $self->helper(logged_in => sub { return exists shift->session->{user_id} });
  $self->helper(
    logout => sub {
      my ($c) = @_;

      delete $c->session->{user_id};
      delete $c->stash->{user};

      $c->session(expires => 1);
      $c->flash_success('You logged out.');

      return $c;
    }
  );
  $self->helper(
    user => sub {
      my ($c) = @_;

      return undef if !$c->logged_in;

      return $c->resultset('User')->find({user_id => $c->session('user_id')});
    }
  );
  $self->helper(
    application => sub {
      my ($c) = @_;

      return undef if !$c->req->headers->header('x-slapbird-apm');

      my $api_key
        = $c->resultset('ApiKey')
        ->find(
        {application_api_key => $c->req->headers->header('x-slapbird-apm')});

      return undef if !$api_key;

      return $api_key->application;
    }
  );
  $self->helper(
    debug => sub {
      shift;    # Remove controller from every debug log.
      Data::Printer::p(@_) unless $ENV{SLAPBIRD_PRODUCTION};
    }
  );
  $self->helper(
    is_uuid => sub {
      my ($c, $uuid) = @_;
      return 0 if !$uuid;
      return ($uuid
          =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
    }
  );
  $self->helper(
    cache => sub {
      return state $memcached = Cache::Memcached::Fast->new({
        servers => [
          exists $ENV{SLAPBIRD_MEMCACHED}
          ? $ENV{SLAPBIRD_MEMCACHED}
          : 'localhost:11211'
        ],
        namespace       => 'slapbird:',
        connect_timeout => 0.2,
        io_timeout      => 0.5,
        close_on_error  => 1,
        nowait          => 1,
        utf8            => 1,
        max_size        => 512 * 1024
      });
    }
  );
  $self->helper(
    github_client => sub { state $client = Slapbird::Client::Github->new(); });
  for (qw(danger success warning)) {
    my $status = $_;
    $self->helper(
      ('flash_' . $status) => sub {
        my $c = shift;
        return $c->flash(message =>
            {status => $status, content => exists $_[1] ? $_[1] : $_[0]});
      }
    );
  }
  $self->helper(
    redirect_with_referrer => sub {
      my ($c, $location, $referrer) = @_;

      $referrer = $c->req->url->path unless $referrer;

      return $c->redirect_to($location . '?referrer=' . $referrer);
    }
  );
  $self->helper(
    application_context_cookie => sub {
      my ($c) = @_;
      my $cookie = $c->cookie('application-context');
      chomp($cookie) if $cookie;
      if ($cookie) {
        return $c->is_uuid($cookie) ? $cookie : undef;
      }

      return undef;
    }
  );
  $self->helper(
    application_context => sub {
      my ($c) = @_;
      return undef unless $c->application_context_cookie;
      return $c->resultset('Application')
        ->find({application_id => $c->application_context_cookie});
    }
  );
  $self->helper(
    apm_application_context => sub {
      my ($c) = @_;
      if (not $c->req->headers->header('x-slapbird-apm')) {
        return undef;
      }
      return $c->resultset('ApiKey')
        ->find(
        {application_api_key => $c->req->headers->header('x-slapbird-apm')});
    }
  );
  $self->helper(
    get_from_to_time => sub {
      my ($c) = @_;

      Carp::croak(
        'get_from_to_time returns 2 args in an array, you must unpack them')
        if !wantarray;

      my $from_time_unclean
        = defined $c->param('from')
        && $c->param('from') ne ''
        ? $c->param('from')
        : (time * 1_000) - (3_600_000);
      my $to_time_unclean = defined $c->param('to')
        && $c->param('to') ne '' ? $c->param('to') : (time * 1_000);

      my $from_time = sprintf('%.2f', $from_time_unclean);
      my $to_time   = sprintf('%.2f', $to_time_unclean);

      return ($from_time, $to_time);
    }
  );
  $self->helper(actions => Slapbird::Actions->helper($self));
  $self->helper(
    stripe => sub {
      return state $stripe = Net::Stripe::Simple->new($ENV{STRIPE_API_KEY});
    }
  );
  $self->helper(
    customer => sub {
      my ($c) = @_;
      Carp::croak('NEVER call app->customer where a user can be logged in!')
        unless $c->logged_in;

      # Users on the free plan have no stripe_id
      return $c->stripe->customers(retrieve => $c->user->stripe_id)
        if $c->user->stripe_id;

      return undef;
    }
  );
  $self->helper(
    secure_key => sub {
      if ($ENV{SLAPBIRD_PRODUCTION}) {
        if (!exists $ENV{SLAPBIRD_SECURE_KEY}) {
          Carp::croak('No SLAPBIRD_SECURE_KEY set!');
        }
        return $ENV{SLAPBIRD_SECURE_KEY};
      }

      return 'secure key';
    }
  );

  my $router = $self->routes;

  # Simple condition to ensure valid application_context
  $router->add_condition(
    has_application_context => sub {
      my ($r, $c, $captures, $required) = @_;

      return 1 if not $required;

      if (not $c->application_context) {
        $c->flash_danger('You need an application to view this page.');
        $c->redirect_to('/dashboard');
        return undef;
      }

      return 1;
    }
  );

  # Set up addons
  for my $addon ($self->resultset('Addons')->all) {
    my $module = 'Slapbird::Addon::' . $addon->module;
    $module->register($self, $router);
  }

  $router->add_condition(
    ('addon_authenticated') => sub {
      my ($r, $c, $captures, $addon) = @_;

      return 1 if not($addon);

      my $api_key
        = $c->resultset('ApiKey')
        ->find(
        {application_api_key => $c->req->headers->header('x-slapbird-apm')});

      if (not $api_key) {
        $c->render(status => 401, text => 'unauthorized');
        return undef;
      }

      my @addons = $api_key->user->user_pricing_plan->addons;

      my $ret = 0;
      for (@addons) {
        if ($_->module eq $addon) {
          $ret = 1;
          last;
        }
      }

      return $ret;
    }
  );


  # Simple condition to see if someone is logged in.
  $router->add_condition(
    authenticated => sub {
      my ($r, $c, $captures, $required) = @_;
      return 1 if not $required;

      if (not $c->logged_in) {
        $c->flash_danger('You need to login to continue.');
        $c->redirect_with_referrer('/login');
        return undef;
      }

      if (!$c->application_context_cookie || !$c->application_context) {
        $c->cookie('application-context' => '', {expires => 1});
        return 1;
      }

      if (!$c->application_context->user_is_allowed($c->user->user_id)) {
        $c->cookie('application-context' => '', {expires => 1});
        $c->redirect_to('/dashboard');
        return undef;
      }

      return 1;
    }
  );

  # Simple condition to see if someones APM key is valid
  $router->add_condition(
    apm_authenticated => sub {
      my ($r, $c, $captures, $required) = @_;
      $required //= 0;
      return 1 if not $required;

      if (not $c->req->headers->header('x-slapbird-apm')) {
        $c->render(status => 401, text => 'unauthorized');
        return undef;
      }

      my $api_key
        = $c->resultset('ApiKey')
        ->find(
        {application_api_key => $c->req->headers->header('x-slapbird-apm')});

      if (not $api_key) {
        $c->render(status => 401, text => 'unauthorized');
        return undef;
      }

      return 1;
    }
  );

  $self->hook(
    around_action => sub {
      my ($next, $c) = @_;

      $next->() && return 1
        unless ($c->logged_in && $c->user->user_pricing_plan);

      if ($c->user->user_pricing_plan->on_hold) {
        $c->redirect_to('/dashboard/on-hold');
        return undef;
      }

      $next->();

      return 1;
    }
  );

  if ($ENV{SLAPBIRD_PRODUCTION}) {
    my $pg    = Mojo::Pg->new($database_uri);
    my @files = sort {
      my $av = ($a =~ /([0-9]+)/si)[0];
      my $bv = ($b =~ /([0-9]+)/si)[0];
      $av <=> $bv;
    } @{Mojo::File->new('mig')->list};

    for (@files) {
      $self->app->log->info('Running migration: ' . $_);
      $pg->migrations->name($_)->from_file($_)->migrate();
    }
  }

  if ($ENV{SLAPBIRD_PRODUCTION} || $ENV{SLAPBIRD_TEST_STRIPE}) {
    try {
      my @pricing_plans = $self->resultset('PricingPlan')->all;
      my %update_lookup = map { lc($_->name) => $_ }
        grep { !defined($_->stripe_id) } @pricing_plans;

      if (%update_lookup) {

        # This uses pricing plan names to lookup their values in stripe.
        for my $stripe_plan (@{$self->stripe->plans('list')->data}) {
          chomp(my $cut = lc((split(' - ', $stripe_plan->name))[1]));
          if (my $plan = $update_lookup{$cut}) {
            $plan->update({stripe_id => $stripe_plan->id});
          }
        }
      }

    }
    catch {
      $self->app->log->warn(
        'Unable to check Stripe/pricing plan associations: ' . $_);
    };
  }


  # Static routes
  for (qw(index getting-started pricing tos privacy docs)) {
    my $slug = slugify($_);
    $slug =~ s/\-/_/gxm;
    $router->any($_ eq 'index' ? '/' : "/$_")->to('static#' . $slug)
      ->name($slug);
  }

  # APM routes
  # (these live in Controllers::API however they DON'T use the /api prefix)
  $router->post('/apm')->requires(apm_authenticated => 1)->to('api-apm#call')
    ->name('apm_post');
  $router->get('/apm/name')->requires(apm_authenticated => 1)
    ->to('api-apm#name')->name('apm_name');

  # Auth routes
  $router->get('/login')->to('auth#login')->name('auth_login');
  $router->get('/login/github')->requires(authenticated => 0)
    ->to('auth#github')->name('auth_github');
  $router->any('/logout')->requires(authenticated => 1)->to('auth#logout')
    ->name('auth_logout');

  # Dashboard routes
  $router->get('/dashboard')->requires(authenticated => 1)
    ->to('dashboard#dashboard')->name('dashboard');
  $router->get('/dashboard/transaction-summary/:endpoint')
    ->requires(authenticated => 1)->to('dashboard#transaction_summary')
    ->name('dashboard_transaction_summary');
  $router->get('/dashboard/transaction/:transaction_id')
    ->requires(authenticated => 1)->to('dashboard#transaction')
    ->name('dashboard_transaction');
  $router->get('/dashboard/new-app')->requires(authenticated => 1)
    ->to('dashboard#new_app')->name('dashboard_new_app');
  $router->get('/dashboard/manage-application')
    ->requires([authenticated => 1, has_application_context => 1])
    ->to('dashboard#manage_application')->name('dahsboard_manage_application');
  $router->post('/dashboard/new-app')->requires(authenticated => 1)
    ->to('dashboard#create_new_app')->name('dashboard_create_new_app');
  $router->get('/dashboard/confirm-delete-application')
    ->requires(authenticated => 1)->to('dashboard#confirm_delete_app')
    ->name('dashboard_confirm_delete_application');
  $router->post('/dashboard/confirm-delete-application')
    ->requires(authenticated => 1)->to('dashboard#delete_app')
    ->name('dashboard_delete_application');
  $router->post('/dashboard/new-api-key')->requires(authenticated => 1)
    ->to('dashboard#new_api_key')->name('dashboard_create_api_key');
  $router->post('/dashboard/rename-application')->requires(authenticated => 1)
    ->to('dashboard#rename_application')->name('dashboard_rename_application');
  $router->post('/dashboard/delete-api-key/:api_key_id')
    ->requires(authenticated => 1)->to('dashboard#delete_api_key')
    ->name('dashboard_delete_api_key');
  $router->get('/dashboard/manage-plan')->requires(authenticated => 1)
    ->to('dashboard#manage_plan')->name('dashboard_manage_plan');
  $router->get('/dashboard/confirm-join-plan')->requires(authenticated => 1)
    ->to('dashboard#confirm_join_plan')->name('dashboard_confirm_join_plan');
  $router->post('/dashboard/confirm-join-plan')->requires(authenticated => 1)
    ->to('dashboard#join_plan')->name('dashboard_join_plan');
  $router->get('/dashboard/confirm-leave-plan')->requires(authenticated => 1)
    ->to('dashboard#confirm_leave_plan')->name('dashboard_confirm_leave_plan');
  $router->post('/dashboard/confirm-leave-plan')->requires(authenticated => 1)
    ->to('dashboard#leave_plan')->name('dashboard_leave_plan');
  $router->get('/dashboard/manage-plan/confirm-remove-user/:user_id')
    ->requires(authenticated => 1)->to('dashboard#confirm_remove_user')
    ->name('dashboard_confirm_remove_user');
  $router->post('/dashboard/manage-plan/confirm-remove-user/:user_id')
    ->requires(authenticated => 1)->to('dashboard#remove_user')
    ->name('dashboard_remove_user');
  $router->get('/dashboard/manage-plan/upgrade')->requires(authenticated => 1)
    ->to('static#upgrade')->name('dashboard_manage_plan_upgrade');

  # Stripe
  $router->post('/dashboard/manage-plan/stripe/upgrade')
    ->requires(authenticated => 1)->to('stripe#checkout_session')
    ->name('stripe_checkout_session');
  $router->get('/dashboard/manage-plan/stripe/portal')
    ->requires(authenticated => 1)->to('stripe#portal')->name('stripe_portal');
  $router->get('/dashboard/manage-plan/stripe/upgrade/success')
    ->requires(authenticated => 1)->to('stripe#checkout_session_success')
    ->name('stripe_checkout_session_success');

  # Invite
  $router->get('/invite/:invite_code')->to('invite#invite')
    ->name('invite_invite');

  # HTMX routes
  $router->get('/htmx/pricing')->requires(authenticated => 0)
    ->to(controller => 'htmx-pricing', action => 'htmx_pricing');
  $router->get('/htmx/dashboard-nav-context')->requires(authenticated => 1)
    ->to(
    controller => 'htmx-dashboard',
    action     => 'htmx_dashboard_nav_context'
    );
  $router->get('/htmx/dashboard-feed')->requires(authenticated => 1)
    ->to(controller => 'htmx-dashboard', action => 'htmx_dashboard_feed');

  # API routes (JSON)
  $router->get('/api/dashboard/graph')->requires(authenticated => 1)
    ->to(controller => 'api-dashboard', action => 'json_graph');

  return $self;
}

1;
