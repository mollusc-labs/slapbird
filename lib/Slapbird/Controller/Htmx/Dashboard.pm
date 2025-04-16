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


package Slapbird::Controller::Htmx::Dashboard;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use Time::HiRes qw(time);
use Mojo::JSON  qw(decode_json);

sub htmx_dashboard_health_check {
  my ($c) = @_;

  if (!$c->user->user_pricing_plan->has_addon('HealthCheck')) {
    return $c->render(text => '', status => 401);
  }

  my $application = $c->application_context;
  my $f = $c->cache->get($application->application_id . '-healthcheck-failed')
    // 0;
  my $t = $c->cache->get($application->application_id . '-healthcheck-total')
    // 0;

  my $failed_percentage = $t != 0 ? ($f / $t) : 0;
  return $c->render(
    template          => 'htmx/_dashboard_health_check',
    failed_percentage => $failed_percentage
  );
}

sub htmx_dashboard_nav_context {
  my ($c) = @_;

  my @applications = $c->user->user_pricing_plan->applications;
  my $allowed_more_applications
    = $c->user->user_pricing_plan->pricing_plan->max_applications
    > scalar(@applications);

  return $c->render(
    template                  => 'htmx/_dashboard_nav_context',
    applications              => \@applications,
    allowed_more_applications => $allowed_more_applications
  );
}

sub htmx_dashboard_feed {
  my ($c) = @_;

  my $dtf
    = $c->resultset('Application')->result_source->storage->datetime_parser;
  my $application_id = $c->application_context->application_id;

  my ($from_time, $to_time) = $c->get_from_to_time();

  my $has_transactions = $c->resultset('HTTPTransaction')
    ->search({application_id => $application_id})->count > 0;

  my $summaries = $c->dbic->storage->dbh_do(sub {
    my ($storage, $dbh) = @_;

    my $query = q{
        SELECT
          handler,
          method,
          end_point,
          AVG(total_time) as avg_time,
          ht.response_code,
          COUNT(*) as count
        FROM applications a
        INNER JOIN (
          SELECT * FROM http_transactions
          WHERE (start_time BETWEEN ? AND ?) AND application_id = ?
        ) ht ON ht.application_id = a.application_id
        GROUP BY a.application_id, ht.method, ht.end_point, ht.response_code, ht.handler
        HAVING a.application_id = ?
        ORDER BY response_code DESC, avg_time DESC
    };

    return $dbh->selectall_arrayref($query, {Slice => {}},
      $from_time, $to_time, $application_id, $application_id);
  });

  return $c->render(
    template         => 'htmx/_dashboard_feed',
    has_transactions => $has_transactions,
    summaries        => $summaries
  );
}

1;
