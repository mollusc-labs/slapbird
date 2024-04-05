package Slapbird::Action::GetTransactionSummaries;

use Moo;
use Types::Standard qw(Str Int LaxNum Object Maybe);

has schema         => (is => 'ro', isa => Object, required => 1);
has page           => (is => 'ro', isa => Int,    default  => sub {1});
has size           => (is => 'ro', isa => Int,    default  => sub {15});
has end_point      => (is => 'ro', isa => Str,    required => 1);
has code           => (is => 'ro', isa => Maybe [Int]);
has from           => (is => 'ro', isa => LaxNum);
has to             => (is => 'ro', isa => LaxNum);
has application_id => (is => 'ro', isa => Str, required => 1);

sub execute {
  my ($self) = @_;

  my $rs = $self->schema->resultset('HTTPTransaction')->search(
    {
      application_id => $self->application_id,
      start_time     => {-between => [$self->from, $self->to]},
      $self->end_point ? (end_point     => $self->end_point) : (),
      $self->code      ? (response_code => $self->code)      : ()
    },
    {
      page     => $self->page,
      rows     => $self->size,
      order_by => {-desc => 'start_time'}
    }
  );

  return ($rs->pager, [$rs->all]);
}

1;