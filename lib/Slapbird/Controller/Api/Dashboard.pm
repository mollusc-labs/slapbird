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


package Slapbird::Controller::Api::Dashboard;

use Mojo::Base 'Mojolicious::Controller';

use strict;
use warnings;

use Slapbird::Advice::ErrorAdvice;
use Const::Fast;

const my $graph_query => q{
SELECT
  application_id,
  type,
  response_code,
  handler,
  (CASE WHEN error IS NULL OR error = '' THEN 0 ELSE 1 END) as was_error,
  total_time,
  start_time,
  end_time
FROM http_transactions
WHERE application_id = ? AND (start_time BETWEEN ? AND ?)
};

sub json_graph {
  my ($c) = @_;

  my ($from_time, $to_time) = $c->get_from_to_time();

  my @transactions = $c->dbic->storage->dbh_do(sub {
    my ($storage, $dbh) = @_;
    return $dbh->selectall_array(
      $graph_query,
      {Slice => {}},
      $c->application_context->application_id,
      $from_time, $to_time
    );
  });

  if (scalar(@transactions) == 0) {
    return $c->render(
      status => 409,
      json   => {message => 'No transactions for this time period'}
    );
  }

  return $c->render(json => \@transactions);
}

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
    = Slapbird::Validator::Application->validate(
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
      application_id => $application->application_id,
      instructions   => $c->render_to_string('htmx/_' . $type . '_instructions')
    }
  );
}

1;
