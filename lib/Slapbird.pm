package Slapbird;

# Slapbird  Copyright (C) 2024  Rawley Fowler, Mollusc Labs
# This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
# This is free software, and you are welcome to redistribute it
# under certain conditions; type `show c' for details.

use Mojo::Base 'Mojolicious';
use Mojo::Log;
use Mojo::Pg;
use Mojo::IOLoop;
use Mojo::File;
use Cache::Memcached::Fast;
use Data::Printer;
use Slapbird::Client::Github;
use Slapbird::Schema;
use Slapbird::Mojolicious::Sessions;
use Slapbird::Actions;
use Slapbird::Util qw(slugify);
use Time::HiRes    qw(time);
use namespace::clean;

our $VERSION = 0.001;

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

sub startup {
  my ($self) = @_;

  $self->sessions(Slapbird::Mojolicious::Sessions->new());

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
  $self->helper(debug => sub { Data::Printer::p(@_); });
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

  my $router = $self->routes;

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
        $c->redirect_to(
          '/dashboard/permission/' . $c->application_context->application_id);
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

  if ($ENV{SLAPBIRD_PRODUCTION}) {
    my $pg = Mojo::Pg->new($database_uri);
    for (@{Mojo::File->new('mig')->list}) {
      $self->app->log->info('Running migration: ' . $_);
      $pg->migrations->name($_)->from_file($_)->migrate();
    }
  }

  # Static routes
  for (qw(index getting-started pricing tos privacy)) {
    my $slug = slugify($_);
    $slug =~ s/\-/_/g;
    $router->any($_ eq 'index' ? '/' : "/$_")->to('static#' . $slug)
      ->name($slug);
  }

  # APM routes
  # (these live in Controllers::API however they DON'T use the /api prefix)
  $router->post('/apm')->requires(apm_authenticated => 1)->to('api-apm#call')
    ->name('apm_post');
  $router->post('/apm/name')->requires(apm_authenticated => 1)
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
  $router->get('/dashboard/manage-application')->requires(authenticated => 1)
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
  $router->post('/dashboard/delete-api-key/:api_key_id')
    ->requires(authenticated => 1)->to('dashboard#delete_api_key')
    ->name('dashboard_delete_api_key');

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
