
use Test::More tests=>8; {
	
	use strict;
	use warnings;
	
	use_ok 'MooseX::Meta::TypeConstraint::Dependent';
	use_ok 'Moose::Util::TypeConstraints';

	## A sample dependent type constraint the requires two ints and see which
	## is the greater.
	
	ok my $int = find_type_constraint('Int') => 'Got Int';
	
	my $dep_tc = MooseX::Meta::TypeConstraint::Dependent->new(
		name => "MooseX::Types::Dependent::Depending" ,
		parent => find_type_constraint('ArrayRef'),
		dependent_type_constraint=>$int,
		comparision_callback=>sub {
			my ($constraining_value, $check_value) = @_;
			return $constraining_value > $check_value ? 0:1;
		},
		constraint_generator =>$int,
		constraint_generator=> sub { 
			my ($callback, $constraining_value, $check_value) = @_;
			return $callback->($constraining_value, $check_value) ? 1:0;
		},
	);
	
	## Does this work at all?

	isa_ok $dep_tc, 'MooseX::Meta::TypeConstraint::Dependent';

	ok !$dep_tc->check([5,10]), "Fails, 5 is less than 10";
	ok !$dep_tc->check(['a',10]), "Fails, 'a' is not an Int.";
	ok !$dep_tc->check([5,'b']), "Fails, 'b' is not an Int either.";
	ok $dep_tc->check([10,5]), "Success, 10 is greater than 5.";
}
