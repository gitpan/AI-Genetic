
package AI::Genetic::IndLIST;

use strict;
use base qw/AI::Genetic::Individual/;

use vars qw/$VERSION/;

$VERSION = 0.01;

1;

# This package doubles as a simple individual (where
# genes are binary - either you have them or you don't)
# and as a base class for IndComplex;

# The individual will take the following options:
# 1. list of genes. This is an anon list where each element
#    is the name of a trait.
# 2. fitness function.

sub new {
  my $self = shift;
  my %args = @_;
  
  my $class = ref($self) || $self;
  
  my $obj = bless {} => $class;
  
  $obj->{FITFUNC} = $args{-fitness}; # ref to fitness function
  $obj->{GENES}   = $args{-genes}; # see comment 1. above.

  # some variables.
  $obj->{CALCED} = 0;		# whether we already calculated fitness value.
  $obj->{SCORE}  = 0;		# the actual fitness value.
  
  return $obj;
}

sub new_random {
  my $self = shift;
  my %args = @_;
  
  my $class = ref($self) || $self;
  
  my $obj = bless {} => $class;
  
  $obj->{FITFUNC} = $args{-fitness}; # ref to fitness function
  $obj->{GENES}   = [];
  
  for my $g (@{$args{-genes}}) {
    push @{$obj->{GENES}} => $g if rand >= 0.5;
  }
  
  # some variables.
  $obj->{CALCED} = 0;		# whether we already calculated fitness value.
  $obj->{SCORE}  = 0;		# the actual fitness value.
  
  return $obj;
}

sub score {
  return $_[0]->_calcFitness;
}

sub _calcFitness {
  my $obj = shift;
  
  unless ($obj->{CALCED}) {
    $obj->{CALCED} = 1;
    $obj->{SCORE}  = $obj->{FITFUNC}->($obj->genes);
  }
  
  return $obj->{SCORE};
}

sub mate {
  my ($me, $her, $rate) = @_;
  
  # This method implements crossover between $me and $her.
  # It is not exactly clear how to proceed here, but I
  # will do the following for now:
  # 1. The $rate will determine whether or not mating occurs.
  #    After that, it doesn't play any role.
  # 2. Check the genes of both parents.
  # 3. Common genes (shared by both parents) have a higher
  #    probability of being passed on (how much?).
  # 4. Genes present in only 1 parent have a 50% chance
  #    of being passed on.
  # 5. According to this, the number of genes of the offspring
  #    need not equal to that of any of its parents.
  # 6. This kind of mating results in only 1 offspring, as
  #    opposed to other methods where the gene strings
  #    are split randomly and recombined creating two
  #    offsprings. Which is better? Shall I simply create
  #    two offsprings using the same procedure?
  
  return [] if rand > $rate;

  my %genes;
  $genes{$_}++ for $me->genes, $her->genes;
  
  my @genes;
  
  for my $gene (keys %genes) {
    next if 0.5 > $genes{$gene} * rand;
    
    push @genes => $gene;
  }
  
  # It is possible that we created an offspring with no
  # genes! So what? As if the parents didn't mate!
  
  return \@genes;
}

sub mutate {
  my ($self, $genes, $rate) = @_;
  
  # This implements mutation.
  # Basically, I iterate through all the genes of
  # the current individual, and randomly determine
  # whether it is to be mutated or not (based on $rate).
  # If so, then I randomly swap it with a gene out of
  # the @$genes list.

  # need to check for duplicate genes

  my @newGenes;
  my @oldGenes = $self->genes;
  my %oldGenes;
  @oldGenes{@oldGenes} = ();


  for my $gene ($self->genes) {
    if (rand > $rate) {		# keep it.
      push @newGenes => $gene;
      next;
    }

    my $newGene = $genes->[rand @$genes];
    if (exists $oldGenes{$newGene}) {
      push @newGenes => $gene; # keep old one if dup.
    } else {
      push @newGenes => $newGene;
    }
  }

  # now, replace the old genes with the new ones.
  $self->{GENES}  = \@newGenes;
  $self->{CALCED} = 0;
  $self->{SCORE}  = 0;
}

sub genes { @{$_[0]->{GENES}} }
