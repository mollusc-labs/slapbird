package Slapbird::Controller::Card;

use Mojo::Base 'Mojolicious::Controller';
use List::Util        qw(first);
use Carp              ();
use Business::CCCheck qw(
  CC_expired
  CC_clean
);

sub add_or_update_card {
  my ($c) = @_;

  if (!$c->user->stripe_id) {
    my (undef, $error)
      = $c->actions->create_stripe_customer_for_user(
      user_id => $c->user->user_id);

    $c->log->error($error);

    if ($error) {
      return $c->render(template => 'util/internal_server_error');
    }
  }

  my $cc_number = CC_clean($c->param('number'));
  my $cc_mm     = $c->param('month');
  my $cc_yy     = $c->param('year');
  my $cc_cvc    = $c->param('cvc');

  if (CC_expired($cc_mm, $cc_yy)) {
    $c->flash_danger(
      'That card is expired. Check your details, and try again.');
    return $c->redirect_to('/dashboard/manage-plan');
  }

  if (!$cc_number) {
    $c->flash_danger(
      'Something went wrong adding your credit card. Check your details, and try again.'
    );
    return $c->redirect_to('/dashboard/manage-plan');
  }

  my ($result, $error) = $c->actions->create_card(
    customer => $c->customer,
    number   => $cc_number,
    mm       => $cc_mm,
    yy       => $cc_yy,
    cvc      => $cc_cvc
  );

  if ($error) {
    $c->flash_danger(
      'Something went wrong adding your credit card. Check your details, and try again.'
    );
    $c->log->error($error);
    return $c->redirect_to('/dashboard/manage-plan');
  }

  $c->redirect_to('/dashboard/manage-plan');
}

1;
