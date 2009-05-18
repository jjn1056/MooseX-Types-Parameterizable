
use Test::More tests=>2; {
	
	use strict;
	use warnings;
	
	use MooseX::Dependent::Types qw(Dependent);
	use MooseX::Types -declare=>[qw(SubDependent)];
	use Moose::Util::TypeConstraints;

	## Raw tests on dependent.
	ok subtype( SubDependent, as Dependent ), 'Create a useless subtype';
	ok ((Dependent->check(1)), 'Dependent is basically an Any');

}
