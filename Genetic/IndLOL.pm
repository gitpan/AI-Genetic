
package AI::Genetic::IndLOL;

use strict;
use AI::Genetic::IndLIST;
use vars qw/$VERSION/;

$VERSION = 0.01;

1;

# Here, every gene is always present, but each gene has a value
# chosen from among a set of given values.

# The individual will take the following options:
# 1. list of genes. This is an anon hash were the keys are the
#    the names of a traits (genes) and the values are their values.
# 2. fitness function.

sub new_random {
  my $self = shift;
  my %args = @_;
  
  my $class = ref($self) || $self;
  
  my $obj = bless {} => $class;
  
  $obj->{FITFUNC} = $args{-fitness}; # ref to fitness function
  $obj->{GENES}   = {};
  
  for my $g (@{$args{-genes}}) {
    my ($gene, @values) = @$g;
    $obj->{GENES}{$gene} = $values[rand @values];
  }
  
  # some variables.
  $obj->{CALCED} = 0;		# whether we already calculated fitness value.
  $obj->{SCORE}  = 0;		# the actual fitness value.
  
  return $obj;
}

sub mate {
  my ($me, $her, $rate) = @_;
  
  # This method implements crossover between $me and $her.
  # It is not exactly clear how to proceed here, but I
  # will do the following for now:
  # 1. The $rate will determine whether or not mating occurs.
  #    After that, it doesn't play any role.
  # 2. Check the genes of both parents.
  # 3. For each gene, randomly select the value from one of the parents.
  
  return () if rand > $rate;
  
  my %babyGenes;
  my $myGenes  = $me ->genes;
  my $herGenes = $her->genes;

  for my $gene (keys %$myGenes) {
    $babyGenes{$gene} = rand > 0.5 ? $herGenes->{$gene} : $myGenes->{$gene};
  }
  
  return \%babyGenes;
}

sub mutate {
  my ($self, $genes, $rate) = @_;
  
  # This implements mutation.
  # Basically, I iterate through all the genes of
  # the current individual, and randomly determine
  # whether it is to be mutated or not (based on $rate).
  # If so, then I randomly pick a new value for it.

  my %values;
  for my $ref (@$genes) {
    my ($g, @values) = @$ref;

    $values{$g} = \@values;
  }

  for my $gene (keys %{$self->{GENES}}) {
    next if rand > $rate;		# keep it.
    $self->{GENES}{$gene} = $values{$gene}[rand @{$values{$gene}}];
  }
  
  $self->{CALCED} = 0;
  $self->{SCORE}  = 0;
}

sub genes { $_[0]->{GENES} }
