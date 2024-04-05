package Slapbird::Controller::Htmx::Dashboard;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use Time::HiRes qw(time);

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
          a.application_id,
          handler,
          method,
          end_point,
          AVG(total_time) as avg_time,
          ht.response_code,
          AVG(response_size) as avg_response_size,
          AVG(request_size) as avg_request_size,
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