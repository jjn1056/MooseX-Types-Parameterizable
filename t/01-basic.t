
use Test::More tests=>9; {
	
	use strict;
	use warnings;
	
	use_ok 'MooseX::Meta::TypeConstraint::Dependent';
	use_ok 'Moose::Util::TypeConstraints';

	## A sample dependent type constraint the requires two ints and sees if
	## the dependent value (the first) is greater than the constraining value
	## (the second).
	
	ok my $int = find_type_constraint('Int') => 'Got Int';
	
	my $dep_tc = MooseX::Meta::TypeConstraint::Dependent->new(
		name => "MooseX::Types::Dependent::Depending" ,
		parent => find_type_constraint('ArrayRef'),
		dependent_type_constraint=>$int,
		comparison_callback=>sub {
			my ($dependent_val, $constraining_val) = @_;
			return ($dependent_val > $constraining_val) ? 1:undef;
		},
		constraining_type_constraint =>$int,
		constraint_generator=> sub {
			my ($dependent_val, $callback, $constraining_val) = @_;
			return $callback->($dependent_val, $constraining_val);
		},
	);

	isa_ok $dep_tc, 'MooseX::Meta::TypeConstraint::Dependent';
	
	ok !$dep_tc->check(['a',10]), "Fails, 'a' is not an Int.";
	ok !$dep_tc->check([5,'b']), "Fails, 'b' is not an Int either.";
	ok !$dep_tc->check({4,1}), "Fails, since this isn't an arrayref";
	ok !$dep_tc->check([5,10]), "Fails, 5 is less than 10";
	ok $dep_tc->check([11,6]), "Success, 11 is greater than 6.";
}
