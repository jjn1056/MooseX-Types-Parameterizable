package MooseX::Types::Parameterizable;

use 5.008;

our $VERSION   = '0.01';
$VERSION = eval $VERSION;

use Moose::Util::TypeConstraints;
use MooseX::Meta::TypeConstraint::Parameterizable;
use MooseX::Types -declare => [qw(Parameterizable)];

=head1 NAME

MooseX::Types::Parameterizable - Create your own Parameterizable Types.

=head1 SYNOPSIS

Within your L<MooseX::Types> declared library module:

    use MooseX::Types::Parameterizable qw(Parameterizable);
	
	subtype Set,
		as class_type("Set::Scalar");

    subtype UniqueInt,
        as Parameterizable[Int, Set],
        where {
            my ($int, $set) = @_;
            return !$set->has($int);
        };
		
	subtype PositiveSet,
		as Set,
		where {
			my ($set) = @_;
			return !grep {$_ <0 } $set->members;
		};
		
    subtype PositiveUniqueInt,
        as UniqueInt[PositiveSet];
	
	my $set = Set::Scalar->new(1,2,3);

	UniqueInt([$set])->check(100);  ## Okay, 100 isn't in (1,2,3)
	UniqueInt([$set])->check(-99);  ## Okay, -99 isn't in (1,2,3)
	UniqueInt([$set])->check(2);  ## Not OK, 2 is in (1,2,3)
	
	PositiveUniqueInt([$set])->check(100);  ## Okay, 100 isn't in (1,2,3)
	PositiveUniqueInt([$set])->check(-99);  ## Not OK, -99 not Positive Int
	PositiveUniqueInt([$set])->check(2);  ## Not OK, 2 is in (1,2,3)
	
	my $negative_set = Set::Scalar->new(-1,-2,-3);
	
	UniqueInt([$negative_set])->check(100);  ## Throws exception
		
=head1 DESCRIPTION

A L<MooseX::Types> library for creating parameterizable types.  A parameterizable type
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
		as Parameterizable[Int, Range],
		where {
			my ($value, $range) = @_;
			return ($value >= $range->{min} &&
			 $value <= $range->{max});
		};
		
	RangedInt([{min=>10,max=>100}])->check(50); ## OK
	RangedInt([{min=>50, max=>75}])->check(99); ## Not OK, 99 exceeds max
	
This throws a hard Moose exception.  You'll need to capture it in an eval or
related exception catching system (see L<TryCatch>).

	RangedInt([{min=>99, max=>10}])->check(10); ## Not OK, not a valid Range!

If you can't accept a hard exception here, you'll need to test the constraining
values first, as in:

	my $range = {min=>99, max=>10};
	if(my $err = Range->validate($range)) {
		## Handle #$err
	} else {
		RangedInt($range)->check(99);
	}
	
Please note that for ArrayRef or HashRef parameterizable type constraints, as in the
example above, as a convenience we automatically ref the incoming type
parameters, so that the above could also be written as:

	RangedInt([min=>10,max=>100])->check(50); ## OK
	RangedInt([min=>50, max=>75])->check(99); ## Not OK, 99 exceeds max
	RangedInt([min=>99, max=>10])->check(10); ## Exception, not a valid Range!

This is the preferred syntax, as it improve readability and adds to the
conciseness of your type constraint declarations.  An exception wil be thrown if
your type parameters don't match the required reference type.

Also not that if you 'chain' parameterization results with a method call like:

	TypeConstraint([$ob])->method;
	
You need to have the "(...)" around the ArrayRef in the Type Constraint
parameters.  This seems to have something to do with the precendent level of
"->".  Patches or thoughts welcomed.  You only need to do this in the above
case which I imagine is not a very common case.

==head2 Subtyping a Parameterizable type constraints

When subclassing a parameterizable type you must be careful to match either the
required type parameter type constraint, or if re-parameterizing, the new
type constraints are a subtype of the parent.  For example:

	subtype RangedInt,
		as Parameterizable[Int, Range],
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
		
Or you could have done the following instead:

	## Subtype of Int for positive numbers
	subtype PositiveInt,
		as Int,
		where {
			my ($value, $range) = @_;
			return $value >= 0;
		};

	## subtype Range to re-parameterize Range with subtypes
	subtype PositiveRange,
		as Range[max=>PositiveInt, min=>PositiveInt];
	
	## create subtype via reparameterizing
	subtype PositiveRangedInt,
		as RangedInt[PositiveRange];

Notice how re-parameterizing the parameterizable type 'RangedInt' works slightly
differently from re-parameterizing 'PositiveRange'  Although it initially takes
two type constraint values to declare a parameterizable type, should you wish to
later re-parameterize it, you only use a subtype of the second type parameter
(the parameterizable type constraint) since the first type constraint sets the parent
type for the parameterizable type.  In other words, given the example above, a type
constraint of 'RangedInt' would have a parent of 'Int', not 'Parameterizable' and for
all intends and uses you could stick it wherever you'd need an Int.

	subtype NameAge,
		as Tuple[Str, Int];
	
	## re-parameterized subtypes of NameAge containing a Parameterizable Int	
	subtype NameBetween18and35Age,
		as NameAge[
			Str,
			PositiveRangedInt[min=>18,max=>35],
		];

One caveat is that you can't stick an unparameterized parameterizable type inside a
structure, such as L<MooseX::Types::Structured> since that would require the
ability to convert a 'containing' type constraint into a parameterizable type, which
is a capacity we current don't have.
	
=head2 Coercions

Parameterizable types have some limited support for coercions.  Several things must
be kept in mind.  The first is that the coercion targets the type constraint
which is being made parameterizable, Not the parameterizable type.  So for example if you
create a Parameterizable type like:

	subtype RequiredAgeInYears,
	  as Int;

	subtype PersonOverAge,
	  as Parameterizable[Person, RequiredAgeInYears]
	  where {
		my ($person, $required_years_old) = @_;
		return $person->years_old > $required_years_old;
	  }

This would validate the following:
	
	my $person = Person->new(age=>35);
	PersonOverAge([18])->check($person);
	
You can then apply the following coercion

	coerce PersonOverAge,
	  from Dict[age=>int],
	  via {Person->new(%$_)},
	  from Int,
	  via {Person->new(age=>$_)};
	  
This coercion would then apply to all the following:

	PersonOverAge([18])->check(30); ## via the Int coercion
	PersonOverAge([18])->check({age=>50}); ## via the Dict coercion

However, you are not allowed to place coercions on parameterizable types that have
had their constraining value filled, nor subtypes of such.  For example:

	coerce PersonOverAge[18],
	  from DateTime,
	  via {$_->years};
	  
That would generate a hard exception.  This is a limitation for now until I can
devise a smarter way to cache the generated type constraints.  However, I doubt
it will be a significant limitation, since the general use case is supported.

Lastly, the constraining value is available in the coercion in much the same way
it is available to the constraint.

	## Create a type constraint where a Person must be in the set
	subtype PersonInSet,
		as Parameterizable[Person, PersonSet],
		where {
			my ($person, $person_set) = @_;
			$person_set->find($person);
		}

	coerce PersonInSet,
		from HashRef,
		via {
			my ($hashref, $person_set) = @_;
			return $person_set->create($hash_ref);
		};

=head2 Recursion

	TBD

=head1 TYPE CONSTRAINTS

This type library defines the following constraints.

=head2 Parameterizable[ParentTypeConstraint, ParameterizableValueTypeConstraint]

Create a subtype of ParentTypeConstraint with a dependency on a value that can
pass the ParameterizableValueTypeConstraint. If ParameterizableValueTypeConstraint is empty
we default to the 'Any' type constraint (see L<Moose::Util::TypeConstraints>).

This creates a type constraint which must be further parameterized at later time
before it can be used to ->check or ->validate a value.  Attempting to do so
will cause an exception.

=cut

Moose::Util::TypeConstraints::get_type_constraint_registry->add_type_constraint(
    MooseX::Meta::TypeConstraint::Parameterizable->new(
        name => 'MooseX::Types::Parameterizable::Parameterizable',
        parent => find_type_constraint('Any'),
		constraint => sub {1},
    )
);

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
