package MooseX::Types::Dependent;

use 5.008;

use Moose::Util::TypeConstraints;
use MooseX::Meta::TypeConstraint::Dependent;
use MooseX::Types -declare => [qw(Depending)];

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:JJNAPIORK';

=head1 NAME

MooseX::Types::Dependent - L<MooseX::Types> constraints that depend on values.

=head1 SYNOPSIS

    subtype UniqueInt,
      as Depending[
        Int,
        sub {
          shift->exists(shift) ? 0:1;
        },
        Set,
      ];

    subtype UniqueInt,
      as Depending {
        shift->exists(shift) ? 0:1;        
      } [Int, Set];

Please see the test cases for more examples.

=head1 DEFINITIONS

The following is a list of terms used in this documentation.

=head2 Dependent Type Constraint

=head2 Check Value

=head2 Constraining Type Constraint

=head2 Constraining Value

=head1 DESCRIPTION

A dependent type is a type constraint whose validity is dependent on a second
value.  You defined the dependent type constraint with a primary type constraint
(such as 'Int') a 'constraining' value type constraint (such as a Set object)
and a coderef which will compare the incoming value to be checked with a value
that conforms to the constraining type constraint.  Typically there should be a
comparision operator between the check value and the constraining value

=head2 Subtyping a Dependent type constraints

TDB: Need discussion and examples.

=head2 Coercions

TBD: Need discussion and example of coercions working for both the
constrainted and dependent type constraint.

=head2 Recursion

Newer versions of L<MooseX::Types> support recursive type constraints.  That is
you can include a type constraint as a contained type constraint of itself.
Recursion is support in both the dependent and constraining type constraint. For
example:

=head1 TYPE CONSTRAINTS

This type library defines the following constraints.

=head2 Depending[$dependent_tc, $codref, $constraining_tc]

Create a subtype of $dependent_tc that is constrainted by a value that is a
valid $constraining_tc using $coderef.  For example:

    subtype GreaterThanInt,
      as Depending[
        Int,
        sub {
          my($constraining_value, $check_value) = @_;
          return $constraining_value > $check_value ? 1:0;
        },
        Int,
      ];

Note that the coderef is passed the constraining value and the check value as an
Array NOT an ArrayRef.

This would create a type constraint that takes an integer and checks it against
a second integer, requiring that the check value is greater.  For example:

    GreaterThanInt->check([5,10]);  ## Fails, 5 is less than 10
    GreaterThanInt->check(['a',10]); ## Fails, 'a' is not an Int.
    GreaterThanInt->check([5,'b']); ## Fails, 'b' is not an Int either.
    GreaterThanInt->check([10,5]); ## Success, 10 is greater than 5.

=head1 EXAMPLES

Here are some additional example usage for structured types.  All examples can
be found also in the 't/examples.t' test.  Your contributions are also welcomed.

TBD

=cut

Moose::Util::TypeConstraints::get_type_constraint_registry->add_type_constraint(
    MooseX::Meta::TypeConstraint::Dependent->new(
        name => "MooseX::Types::Dependent::Depending" ,
        parent => find_type_constraint('ArrayRef'),
        constraint_generator=> sub { 
			my ($dependent_val, $callback, $constraining_val) = @_;
			return $callback->($dependent_val, $constraining_val);
        },
    )
);

=head1 SEE ALSO

The following modules or resources may be of interest.

L<Moose>, L<MooseX::Types>, L<Moose::Meta::TypeConstraint>,
L<MooseX::Meta::TypeConstraint::Dependent>

=head1 TODO

Here's a list of stuff I would be happy to get volunteers helping with:

=over 4

=item Examples

Examples of useful code with both POD and ideally a test case to show it
working.

=back

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
