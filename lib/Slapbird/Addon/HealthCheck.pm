# This file is apart of SlapbirdAPM, a Free and Open-Source
# web application APM for Perl 5 web applications.
#
# Copyright (C) 2025  Mollusc Labs.
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


package Slapbird::Addon::HealthCheck;

use Moo;
use Carp ();
use Mojo::UserAgent;
use Const::Fast;

const my $ua              => Mojo::UserAgent->new();
const my $HOUR_IN_SECONDS => 3_600;

sub register {
  my ($pkg, $c, $r) = @_;

  if (ref($pkg)) {
    Carp::croak('Cannot register object, register is static.');
  }

  $r->get('/apm/healthcheck')->requires(addon_authenticated => 1)
    ->to('api-apm#healthcheck');

  push @{$c->cronjobs}, {
    health_checks => {
      base    => 'utc',
      crontab => '*/5 * * * *',
      code    => sub {
        my $health_check_addon
          = $c->resultset('Addon')->find({module => 'HealthCheck'});
        my @user_pricing_plan_addons = $c->resultset('UserPricingPlanAddon')
          ->search({addon_id => $health_check_addon->addon_id})->all;

        my %master_conf = map { %{$_->config} } @user_pricing_plan_addons;

        for my $application_id (keys %master_conf) {
          my $app_conf = $master_conf{$application_id};

          next unless $app_conf->{receive_emails};

          my $response = $ua->head($app_conf->{endpoint})->result;
          my $success  = $response->is_success;
          $c->cache->get($application_id . '-healthcheck-total')
            // $c->cache->set($application_id . '-healthcheck-total',
            0, $HOUR_IN_SECONDS * 24);
          $c->cache->get($application_id . '-healthcheck-failed')
            // $c->cache->set($application_id . '-healthcheck-failed',
            0, $HOUR_IN_SECONDS * 24);

          $c->cache->incr($application_id . '-healthcheck-total');
          if (!$success) {
            $c->cache->incr($application_id . '-healthcheck-failed');

            if ($c->cache->get($application_id . '-healthcheck-failed') > 5
              && !$c->cache->get($application_id . '-healthcheck-alerted'))
            {
              my $application = $c->resultset('Application')
                ->find({application_id => $application_id});
              my $application_name = $application->name;
              my $user             = $application->user_pricing_plan->user;
              $c->actions->send_email(
                to      => $user->email,
                subject => "ALERT!! HEALTHCHECK FAILURE FOR $application_name",
                body    =>
                  qq[$application_name failed healtcheck more than 5 times in the last 24 hours, https://slapbirdapm.com]
              );
              $c->cache->set($application_id . '-healthcheck-alerted',
                1, $HOUR_IN_SECONDS * 24);
            }
          }
        }
      }
    }
  };

  return;
}

sub param_keys {
  my @k = qw(endpoint cert_alerts receive_emails);
  return wantarray ? @k : \@k;
}

1;
