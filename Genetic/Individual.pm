
package AI::Genetic::Individual;

use strict;

1;

# nothing much here .. just the docs ..

__END__

=head1 NAME

AI::Genetic::Individual - Package for AI::Genetic Individuals.

=head1 SYNOPSIS

See L<AI::Genetic>.

=head1 DESCRIPTION

This class implements an AI::Genetic::Individual object. Those are used
by the AI::Genetic (GA) module. They are the "organisms", if you will, that
the GA module evolves. They are accessible via the C<get_fittest()> method
defined in the AI::Genetic class. Please consult L<AI::Genetic>.

=head1 CLASS METHODS

The following are the public methods that can be used.

=over 4

=item I<$ind>-E<gt>B<score>()

This returns the current fitness score of the individual.

=item I<$ind>-E<gt>B<genes>()

This returns the list of genes for the individual.

For LIST individuals (see L<AI::Genetic/"GENES">), it returns
a list of the ON genes of the individual.

For LOL individuals (see L<AI::Genetic/"GENES">), it returns
an anonymous hash. The keys of this hash are the the
genes, and the values are the values of the genes. At this point, AI::Genetic
passes the same reference that it is storing inside of it. So, if you modify
this hash, it will affect the actual individual. Please be careful.

=back

=head1 AUTHOR

Ala Qumsieh I<aqumsieh@cpan.org>

=head1 COPYRIGHTS

This module is distributed under the same terms as Perl itself.

=cut

