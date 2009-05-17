package MooseX::Dependent::Types;

use 5.008;

use Moose::Util::TypeConstraints;
use MooseX::Dependent::Meta::TypeConstraint::Parameterizable;
use MooseX::Types -declare => [qw(Dependent)];

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:JJNAPIORK';

=head1 NAME

MooseX::Dependent::Types - L<MooseX::Types> constraints that depend on values.

=head1 SYNOPSIS

Within your L<MooseX::Types> declared library module:

    use MooseX::Dependent::Types qw(Dependent);

    subtype UniqueID,
        as Dependent[Int, Set],
        where {
            my ($int, $set) = @_;
            return $set->find($int) ? 0:1;
        };

=head1 DESCRIPTION

A L<MooseX::Types> library for creating dependent types.  A dependent type
constraint for all intents and uses is a subclass of a parent type, but adds a
secondary type parameter which is available to constraint callbacks (such as
inside the 'where' clause) or in the coercions.

This allows you to create a type that has additional runtime advice, such as a
set of numbers within which another number must be unique, or allowable ranges
for a integer, such as in:

	subtype Range,
		as Dict[max=>Int, min=>Int],
		where {
			my ($range) = @_;
			return $range->{max} > $range->{min};
		};

	subtype RangedInt,
		as Dependent[Int, Range],
		where {
			my ($value, $range) = @_;
			return ($value >= $range->{min} &&
			 $value =< $range->{max});
		};
		
	RangedInt[{min=>10,max=>100}]->check(50); ## OK
	RangedInt[{min=>50, max=>75}]->check(99); ## Not OK, 99 exceeds max
	RangedInt[{min=>99, max=>10}]->check(10); ## Not OK, not a valid Range!
	
Please note that for ArrayRef or HashRef dependent type constraints, as in the
example above, as a convenience we automatically ref the incoming type
parameters, so that the above could also be written as:

	RangedInt[min=>10,max=>100]->check(50); ## OK
	RangedInt[min=>50, max=>75]->check(99); ## Not OK, 99 exceeds max
	RangedInt[min=>99, max=>10]->check(10); ## Not OK, not a valid Range!

This is the preferred syntax, as it improve readability and adds to the
conciseness of your type constraint declarations.  An exception wil be thrown if
your type parameters don't match the required reference type.

==head2 Subtyping a Dependent type constraints

When subclassing a dependent type you must be careful to match either the
required type parameter type constraint, or if re-parameterizing, the new
type constraints are a subtype of the parent.  For example:

	subtype RangedInt,
		as Dependent[Int, Range],
		where {
			my ($value, $range) = @_;
			return ($value >= $range->{min} &&
			 $value =< $range->{max});
		};

Example subtype with additional constraints:

	subtype PositiveRangedInt,
		as RangedInt,
		where {
			shift >= 0;  			
		};
		
Or you could have done the following instead (example of re-paramterizing)

	## Subtype of Int for positive numbers
	subtype PositiveInt,
		as Int,
		where {
			shift >= 0;
		};

	## subtype Range to re-parameterize Range with subtypes
	subtype PositveRange,
		as Range[max=>PositiveInt, min=>PositiveInt];
	
	## create subtype via reparameterizing
	subtype PositiveRangedInt,
		as RangedInt[PositveRange];

Notice how re-parameterizing the dependent type 'RangedInt' works slightly
differently from re-parameterizing 'PositiveRange'?  Although it initially takes
two type constraint values to declare a dependent type, should you wish to
later re-parameterize it, you only use a subtype of the second type parameter
(the dependent type constraint) since the first type constraint sets the parent
type for the dependent type.  In other words, given the example above, a type
constraint of 'RangedInt' would have a parent of 'Int', not 'Dependent' and for
all intends and uses you could stick it wherever you'd need an Int.

	subtype NameAge,
		as Tuple[Str, Int];
	
	## re-parameterized subtypes of NameAge containing a Dependent Int	
	subtype NameBetween18and35Age,
		as NameAge[
			Str,
			PositiveRangedInt[min=>18,max=>35],
		];

One caveat is that you can't stick an unparameterized dependent type inside a
structure, such as L<MooseX::Types::Structured> since that would require the
ability to convert a 'containing' type constraint into a dependent type, which
is a capacity we current don't have.
	
=head2 Coercions

    TBD: Need discussion and example of coercions working for both the
    constrainted and dependent type constraint.
	
	subtype OlderThanAge,
		as Dependent[Int, Dict[older_than=>Int]],
		where {
			my ($value, $dict) = @_;
			return $value > $dict->{older_than} ? 1:0;
		};

Which should work like:

	OlderThanAge[{older_than=>25}]->check(39);  ## is OK
		
	coerce OlderThanAge,
		from Tuple[Int, Int],
		via {
			my ($int, $int);
			return [$int, {older_than=>$int}];
		};

=head2 Recursion

Newer versions of L<MooseX::Types> support recursive type constraints.  That is
you can include a type constraint as a contained type constraint of itself.
Recursion is support in both the dependent and constraining type constraint. For
example, if we assume an Object hierarchy like Food -> [Grass, Meat]
	
	TODO: DOES THIS EXAMPLE MAKE SENSE?
	
    subtype Food,
		as Dependent[Food, Food],
		where {
			my ($value, $allowed_food_type) = @_;
			return $value->isa($allowed_food_type);
		};
	
	my $grass = Food::Grass->new;
	my $meat = Food::Meat->new;
	my $vegetarian = Food[$grass];
	
	$vegetarian->check($grass); ## Grass is the allowed food of a vegetarian
	$vegetarian->check($meat); ## BANG, vegetarian can't eat meat!

=head1 TYPE CONSTRAINTS

This type library defines the following constraints.

=head2 Dependent[ParentTypeConstraint, DependentValueTypeConstraint]

Create a subtype of ParentTypeConstraint with a dependency on a value that can
pass the DependentValueTypeConstraint. If DependentValueTypeConstraint is empty
we default to the 'Any' type constraint (see L<Moose::Util::TypeConstraints>).

This creates a type constraint which must be further parameterized at later time
before it can be used to ->check or ->validate a value.  Attempting to do so
will cause an exception.

=cut

Moose::Util::TypeConstraints::get_type_constraint_registry->add_type_constraint(
    MooseX::Dependent::Meta::TypeConstraint::Parameterizable->new(
        name => 'MooseX::Dependent::Types::Dependent',
        parent => find_type_constraint('ArrayRef'),
        constraint_generator=> sub { 
			my ($dependent_val, $callback, $constraining_val) = @_;
			return $callback->($dependent_val, $constraining_val);
        },
    )
);

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
