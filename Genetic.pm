
package AI::Genetic;

use strict;
use vars qw/$VERSION/;

$VERSION = 0.01;

1;

# The initial population is a list of anonymous lists of characteristics.
# The -genes option specifies all the possible characteristics a child
# can have. This is used to generate random individuals if needed and
# to introduce mutations (??).

# -genes can be specified in one of two ways:
# 1) LIST:
#    an anonymous list of genes. In this case, a gene is binary: it's
#    either present or not (on/off). An off-gene will be missing from
#    the list returned by genes().
# 2) LOL:
#    an anonymous list of sublists, one for each gene. Each sublist
#    contains the gene name, and the possible values it can take.
#    eg: -genes => [[qw/geneA 0 1 2 3/], [qw/geneB a b c d/]]

sub new {
  my $self = shift;
  my %args = @_;
  
  my $class = ref($self) || $self;
  
  my $obj = bless {} => $class;

  $obj->{FITFUNC}    = $args{-fitness};	# fitness function
  $obj->{POPSIZE}    = $args{-population}; # max population size
  $obj->{MUTPROB}    = $args{-mutation}; # mutation probability
  $obj->{CROSSRATE}  = $args{-crossover}; # crossover rate
  $obj->{INIT}       = $args{-init} || []; # initial population
  $obj->{GENES}      = $args{-genes}; # list of possible genes. Needed!
  
  # and, some defaults:
  $obj->{POPSIZE}    = 100  unless defined $obj->{POPSIZE};
  $obj->{MUTPROB}    = 0.05 unless defined $obj->{MUTPROB};
  $obj->{CROSSRATE}  = 0.95 unless defined $obj->{CROSSRATE};
  
  # now .. some variables.
  $obj->{PEOPLE}     = [];	# a list of individuals in the population
  $obj->{GENERATION} = 0;	# current generation
  
  # some variables for optimization.
  $obj->{SORTED}     = 0;	# whether or not the list of people is sorted or not

  # now check the format of -genes. Not a strict check.
  # Assume users know what they're doing.
  if (ref $obj->{GENES}[0]) { #lol
    $obj->{INDIVIDUAL} = 'AI::Genetic::IndLOL';
  } else {
    $obj->{INDIVIDUAL} = 'AI::Genetic::IndLIST';
  }

  eval "require $obj->{INDIVIDUAL}";
  
  $obj->_initFill;
  
  return $obj;
}

# This subroutine is used to initially fill the population.
# If the initial population specified is less than the number
# of max population size, random individuals are generated.

sub _initFill {
  my $obj = shift;
  
  for my $i (@{$obj->{INIT}}) {
    # might need to do a deepcopy of $i here in order
    # to prevent programmer from destroying this value.
    # (could be anon hash or anon list).
    push @{$obj->{PEOPLE}} => $obj->{INDIVIDUAL}->new
      (
       -fitness => $obj->{FITFUNC},
       -genes   => $i,
      );
  }
  
  # in case we don't have enough individuals, create
  # some random ones.
  
  for my $i (scalar @{$obj->{INIT}} .. $obj->{POPSIZE} - 1) {
    # create a random combination of genes.
    push @{$obj->{PEOPLE}} => $obj->{INDIVIDUAL}->new_random
      (
       -fitness => $obj->{FITFUNC},
       -genes   => $obj->{GENES},
      );
  }
  
  $obj->{SORTED}    = 0;
}

# This method calculates the score of every individual
# by calling the score() method.

sub _calcAll {
  my $obj = shift;
  
  for my $i (@{$obj->{PEOPLE}}) {
    $i->score;
  }
  
  $obj->{SORTED}    = 0;
}

# This method sorts the generation of individuals based on their scores.

sub _sortAll {
  my $obj = shift;
  
  return if $obj->{SORTED};
  
  $obj->{SORTED} = 1;
  $obj->{PEOPLE} = [sort { $b->score <=> $a->score } @{$obj->{PEOPLE}}];
}

# This returns the N fittest individuals.

sub get_fittest {
  my ($obj, $N) = @_;

  # limit N
  $N ||= 1;
  $N   = @{$obj->{PEOPLE}} if $N > $obj->{PEOPLE};

  my @r;
  push @r => $obj->{PEOPLE}[$_] for 1 .. $N;

  return $r[0] if $N == 1 && not wantarray;
  return @r;
}

# Temp pretty-print a report.

sub report {
  my $obj = shift;
  
  print "\nIn generation $obj->{GENERATION},  I have:\n\n";
  
  $obj->_calcAll;
  $obj->_sortAll;
  
  for my $i (@{$obj->{PEOPLE}}) {
    my $string = join '|' => $i->genes;
    my $score  = $i->score;
    
    print "Score for '$string' == $score.\n";
  }
}

sub evolve {
  my ($obj, $gens) = @_;
  
  # Evolve for $gens generations. Each generation
  # is one pass through the following 3 steps:
  # 1. Selection
  # 2. Crossover
  # 3. Mutation
  
  # set $gens to 1 unless a value is specified.
  $gens = 1 unless defined $gens;
  
  # don't do anything if $gens is not positive
  return if $gens < 1;
  
  for my $i (1 .. $gens) {
    $obj->_selection;
    $obj->_crossover;
    $obj->_mutation;
    $obj->{GENERATION}++;
  }
}

sub _selection {
  my $obj = shift;
  
  # For now, I simply select the top half of our
  # population. More elaborate choosing mechanisms
  # can be implemented like adding some randomness
  # to the procedure.
  
  # make sure we have an even number of individuals left
  # (makes it easier to mate them in pairs).
  
  $obj->_calcAll;
  $obj->_sortAll;
  
  my $index = $obj->{POPSIZE} / 2;
  $index++ if $index % 2;
  
  splice @{$obj->{PEOPLE}}, $index;
}

sub _crossover {
  my $obj = shift;
  
  # First, we pair the individuals randomly.
  # Then we mate them.
  
  my @pairs;
  my @temp = @{$obj->{PEOPLE}};
  
  while (@temp) {
    my @x;
    push @x => shift  @temp;
    push @x => splice @temp, int(rand @temp), 1;
    
    push @pairs => \@x;
  }
  
  # let's mate!
  for my $p (@pairs) {
    # Mate them twice to get two offsprings.
    for (1 .. 2) {
      # returns empty list if no mating occurs!
      my $genes = $p->[0]->mate($p->[1], $obj->{CROSSRATE});

      next if ref($genes) eq 'ARRAY' && !@$genes;
      push @{$obj->{PEOPLE}} => $obj->{INDIVIDUAL}->new
	(
	 -fitness => $obj->{FITFUNC},
	 -genes   => $genes,
	);
    }
  }
  
  $obj->{SORTED}    = 0;
}

sub _mutation {
  my $obj = shift;
  
  # allow each individual to mutate according to
  # the given mutation probability.
  # What does mutation mean in this case?!
  # When we had our genes as bits, mutation simply
  # means flipping of 1s to 0s and vice versa.
  # But, what is it now?
  # Look in Package AI::Genetic::Individual::Base.
  
  $_->mutate($obj->{GENES}, $obj->{MUTPROB})
    for @{$obj->{PEOPLE}};
}

__END__

=head1 NAME

AI::Genetic - A pure Perl genetic algorithm implementation.

=head1 SYNOPSIS

    use AI::Genetic;
    my $ga = new AI::Genetic(
			 -fitness    => sub { rand },
			 -genes      => [qw/geneA geneB geneC/],
			 -population => 500,
			 -crossover  => 0.9,
			 -mutation   => 0.01,
			);

=head1 DESCRIPTION

This module implements a Genetic Algorithm (GA) in pure Perl.
Other Perl modules that achieve the same thing (perhaps better,
perhaps worse) do exist. Please check CPAN. I mainly wrote this
module to satisfy my own needs, and to learn something about GAs
along the way.

I will not go into the details of GAs here, but here are the
bare basics. Plenty of information can be found on the web.

In a GA, a population of individuals compete for survival. Each
individual is designated by a set of genes that defines its
behaviour. Individuals that perform better (as defined by the
fitness function) have a higher chance of mating with other
individuals. When two individuals mate, they swap some of
their genes, resulting in an individual that has properties
from both of its "parents". Every now and then, a mutation
occurs where some gene randomly changes value, resulting in
a different individual.

A GA implementation runs for a discrete number of time steps
call I<generations>. During each generation, the following happens:

=over 4

=item B<1. Selection>

Here the performances of all the individuals are evaluated
based on the fitness function, and each is given a specific
fitness value. The higher the value, the bigger the chance
of an individual passing its genes on in future generations.
Currently, individuals are ranked by fitness, and the top
half are selected for subsequent steps.

=item B<2. Crossover>

Here, individuals selected are randomly paired up for
crossover (aka I<sexual reproduction>). This is further
controlled by the crossover rate specified and may result in
a new offspring individual that contains genes common to
both parents. More details are given in L</"CROSSOVER">.

=item B<3. Mutation>

In this step, each individual is given the chance to mutate
based on the mutation probability specified.
More details are given in L</"MUTATION">.

=back

=head1 CLASS METHODS

Here are the public methods.

=over 4

=item I<$ga>-E<gt>B<new>(I<options>)

This is the constructor. It accepts options in the form of
hash-value pairs. These are:

=over 8

=item B<-population>

This defines the size of the population, i.e. how many individuals
to simultaneously exist at each generation. Defaults to 100.

=item B<-crossover>

This defines the crossover rate. Defaults to 0.95.

=item B<-mutation>

This defines the mutation rate. Defaults to 0.05.

=item B<-genes>

This defines the gene pool. Please see L</"GENES">.

=item I<-init>

This defines the genes of any initial individuals you want to exist
at generation 0. Please see L</"GENES">.

=item I<-fitness>

This defines a fitness function. It expects a reference to a subroutine.
More details are given in L</"FITNESS FUNCTION">.

=back

=item I<$ga>-E<gt>B<evolve>(?I<num_generations>?)

This method causes the GA to evolve the specified number of
generations. If no argument is given, it defaults to 1 generation.
In each generation, the 3 steps defined above (selection -> crossover -> mutation)
are executed.

=item I<$ga>-E<gt>B<get_fittest>(?I<N>?)

This returns the I<N> fittest individuals. If not specified,
N defaults to 1. The actual AI::Genetic::Individual objects are returned.
You can use the C<genes()> and C<score()> methods to get the genes and the
scores of the individuals. Please
check L<AI::Genetic::Individual> for details.

=back

=head1 GENES

There are two ways to specify the gene pool to the GA. For lack of
imagination, I call them B<LIST> and B<LOL>. They do not mix. So
please use one or the other.

=over 4

=item B<LIST>

This is the simplest way to pass the gene pool, but it has its limits.
Here, you pass the argument to -genes as an anonymous list of all the
possible genes:

C<-genes =E<gt> [qw/geneA geneB geneC geneD .../]>

The catch here is that genes are binary, so they can assume either an
ON or an OFF value. Genes that are off will not be present in an
individuals genome.

You can specify an initial population of LIST individuals using the -init
option as follows:

C<-init =E<gt> [
          [qw/geneA geneC geneD/],
          [qw/geneB geneC/],
         ]>

This defines two individuals: the first has genes geneA, geneC and geneD; and
the second has two genes: geneB and geneC.

=item B<LOL>

=item

Here, each gene can have a range of possible values, which have to
be passed on to the GA object as so:

C<-genes =E<gt> [
            [qw/geneA 0 1 2 3 4],
            [qw/geneB a b c d e],
            ....
           ]>

In this example, geneA is allowed to have any of the values 0, 1,
2, 3 or 4. Similarly, geneB can have only one of the values to
its right. In this case, all genes will be present in each
individual, but the gene will have a value chosen from its
respective list.

Pleas note: for now, you have to specify all the values that a gene
can take. Perhaps in the future I will support specifying a range of
values instead, but not now :)

You can specify an initial population of LOL individuals using the -init
option as follows:

C<-init =E<gt> [
          {
           geneA =E<gt> 1,
           geneB =E<gt> 'b',
           geneC =E<gt> 5,
          }
         ]>

This defines one individual with the genes having the specified values.
Note here that you have to specify values for ALL genes. This is necessary
and failing to do so will create warnings/errors at I<run-time>.

=back

=head1 CROSSOVER

I am aware that many crossover techniques exist. I have chosen only
one that suited my needs. Basically, fit individuals are paired up
randomly. Whether mating actually occurs depends on the crossover
rate defined by the -crossover option.

For LIST individuals (see L</"GENES">), the genes of both parents are
inspected. Genes shared by both parents have a higher chance of being
passed on. Genes present in only one parent have a 50% chance of making
it to the child. Genes in neither parent can not pass on to the child.
Based on this, genes are randomly selected for the child. Note that
under this scheme, the number of genes in both parents need NOT be equal
to each other, or to the number of genes in the child. Note also that this
might result in a child with no genes, in which case it is assumed that
the parent individuals did not mate at all.

For LOL individuals (see L</"GENES">), both parents have all the genes,
but with potentially
different values. Here, the child individual will have all the genes, and
the value of each gene is randomly chosen among the two values of the parents'.

If you require a different crossover technique, please let me know.

=head1 MUTATION

Again, I'm aware of the many mutation techniques out there. Again, I have
chosen something simple that suits my needs.

For LIST individuals (see L</"GENES">), each individual has a list of the
ON genes only. Iterating through this list, the mutation probability determines
whether this gene is to be mutated or not. If so, then another gene is chosen
from the original list of all possible genes, and replaces the current
gene. Note that duplicate genes are not allowed. If a gene is to be replaced
by another one that is already in the genome, then no mutation occurs.

For LOL individuals (see L</"GENES">), all genes are present in each
individual. Iterating through all the genes, the mutation probability determines
whether the gene is to mutate or not. If so, then a new value is chosen from
the original list of possible values.

Again, if you require a different mutation technique, please let me know.

=head1 FITNESS FUNCTION

AI::Genetic expects the fitness function to be an anonymous subroutine, defined
by the user. It is used during selection to calculate a I<fitness> value for
each individual. The higher the value, the more fit the individual. The
arguments to this subroutine depend on the type of genome used. The result
is expected to be a scalar number, that defines the fitness of the individual.

For LIST individuals (see L</"GENES">), the input arguments to the fitness
function will be a list of the ON genes of the individual.

For LOL individuals (see L</"GENES">), the input argument to the fitness
function will be an anonymous hash. The keys of this hash are the the
genes, and the values are the values of the genes. At this point, AI::Genetic
passes the same reference that it is storing inside of it. So, if you modify
the gene within the fitness function subroutine, it will affect the actual
individual. Please be careful.

=head1 BUGS

You tell me :)

This module is still in early beta mode. So please send any bugs or
feature requests to me (See L</"AUTHOR">).

=head1 INSTALLATION

Either the usual:

	perl Makefile.PL
	make
	make install

or just stick it somewhere in @INC where perl can find it. It's in pure Perl.

=head1 AUTHOR

Ala Qumsieh I<aqumsieh@cpan.org>

=head1 COPYRIGHTS

This module is distributed under the same terms as Perl itself.

=cut

