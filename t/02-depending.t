use Test::More tests=>15; {
    
    use strict;
    use warnings;
    
    use Test::Exception;
    use MooseX::Types::Dependent qw(Depending);
 	use MooseX::Types::Moose qw(Int Str Object ArrayRef HashRef Maybe);
	use MooseX::Types -declare => [qw(
        IntGreaterThanInt
        UniqueInt
    )];
    
    ## The dependent value must exceed the constraining value
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
    
    ## The dependent value cannot exist in the constraining arrayref
    subtype UniqueInt,
      as Depending[
        Int,
        sub {
            my ($dependent_int, $constraining_arrayref) = @_;
            ## Yes, this is braindead way to check for uniques in an array
            ## but this doesn't require additional dependencies.
            (grep { $_ == $dependent_int} @$constraining_arrayref) ? 0:1
        },
        ArrayRef[Int],
      ];
      
    isa_ok UniqueInt, 'MooseX::Meta::TypeConstraint::Dependent';
    ok !UniqueInt->check(['a',[1,2,3]]), '"a" not an Int';
    ok !UniqueInt->check([1,['b','c']]), '"b","c" not an arrayref';    
    ok !UniqueInt->check([1,[1,2,3]]), 'not unique in set';
    ok !UniqueInt->check([10,[1,10,15]]), 'not unique in set';
    ok UniqueInt->check([2,[3..6]]), 'PASS unique in set';
    ok UniqueInt->check([3,[100..110]]), 'PASS unique in set';    
}
