use Test::More tests=>8; {
    
    use strict;
    use warnings;
    
    use Test::Exception;
    use MooseX::Types::Dependent qw(Depending);
 	use MooseX::Types::Moose qw(Int Str Object ArrayRef HashRef Maybe);
	use MooseX::Types -declare => [qw(
        IntGreaterThanInt
    )];
    
    subtype IntGreaterThanInt,
      as Depending[
        Int,
        sub {
			my ($dependent_val, $constraining_val) = @_;
			return ($dependent_val > $constraining_val) ? 1:undef;
        },
        Int,
      ];
      
	isa_ok IntGreaterThanInt, 'MooseX::Meta::TypeConstraint::Dependent';
	
	ok !IntGreaterThanInt->check(['a',10]), "Fails, 'a' is not an Int.";
	ok !IntGreaterThanInt->check([5,'b']), "Fails, 'b' is not an Int either.";
	ok !IntGreaterThanInt->check({4,1}), "Fails, since this isn't an arrayref";
	ok !IntGreaterThanInt->check([5,10]), "Fails, 5 is less than 10";
	ok IntGreaterThanInt->check([11,6]), "Success, 11 is greater than 6.";
	ok IntGreaterThanInt->check([12,1]), "Success, 12 is greater than1.";
	ok IntGreaterThanInt->check([0,-10]), "Success, 0 is greater than -10.";
}
