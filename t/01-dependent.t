
use Test::More tests=>5; {
	
	use strict;
	use warnings;
	
	use MooseX::Dependent::Types qw(Dependent);
	use MooseX::Types -declare=>[qw(SubDependent)];
	use Moose::Util::TypeConstraints;

	ok subtype( SubDependent, as Dependent ),
	  'Create a useless subtype';
	ok Dependent->check(1),
	  'Dependent is basically an Any';
	ok SubDependent->check(1),
	  'SubDependent is basically an Any';
	is Dependent->parent, 'Any',
	  'Dependent is an Any';
	is SubDependent->parent, 'MooseX::Dependent::Types::Dependent',
	  'SubDependent is a Dependent';
	is Dependent->get_message, "Validation failed for 'MooseX::Dependent::Types::Dependent' failed with value undef",
	  'Got Expected Message'
	warn SubDependent->get_message;
}

__END__

check
validate
get_message
name
equals
is_a_type_of
is_subtype_of