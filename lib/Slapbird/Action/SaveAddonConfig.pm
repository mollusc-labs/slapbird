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


package Slapbird::Action::SaveAddonConfig;

use Moo;
use Types::Standard qw(HashRef Str);

has schema                     => (is => 'ro', required => 1);
has params                     => (is => 'ro', required => 1, isa => HashRef);
has module                     => (is => 'ro', required => 1, isa => Str);
has application_id             => (is => 'ro', required => 1, isa => Str);
has user_pricing_plan_addon_id => (is => 'ro', required => 1, isa => Str);

sub execute {
  my ($self) = @_;

  chomp(my $module = "Slapbird::Addon::" . $self->module);
  chomp(my $validation_module
      = "Slapbird::Validator::" . $self->module . 'Config');

  my $user_pricing_plan_addon = $self->schema->resultset('UserPricingPlanAddon')
    ->find({user_pricing_plan_addon_id => $self->user_pricing_plan_addon_id});

  my $config = $user_pricing_plan_addon->config;
  eval "use $module";
  eval "use $validation_module";

  my @keys = $module->param_keys;
  my $json = {};

  for (@keys) {
    $json->{$_} = $self->params->{$_};
  }

  my ($ok, $errors) = $validation_module->validate($json);

  $config->{$self->application_id} = $ok;

  if ($errors) {
    return undef, $errors;
  }

  return $user_pricing_plan_addon->update({config => $config}), undef;
}

1;
