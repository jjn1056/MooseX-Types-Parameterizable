use Test::More tests=>24; {
    
    use strict;
    use warnings;
    
    use Test::Exception;
    use MooseX::Types::Dependent qw(Depending);
 	use MooseX::Types::Moose qw(Int Str Object ArrayRef HashRef Maybe);
	use MooseX::Types -declare => [qw(
        IntGreaterThanInt
        UniqueInt
		UniqueInt2
    )];
	
	## sugar for alternative syntax: depending {} TC,TC
	sub depending(&@) {
		my ($coderef, $dependent_tc, $constraining_tc, @args) = @_;		
		if(@args) {
			return (Depending[$dependent_tc,$coderef,$constraining_tc],@args);
		} else {
			return Depending[$dependent_tc,$coderef,$constraining_tc];
		}
	}
    
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
    
    ## The dependent value cannot exist in the constraining arrayref.  Also, it
	## (the dependent type) must exceed 2.
    subtype UniqueInt,
      as Depending[
        Int,
        sub {
            my ($dependent_int, $constraining_arrayref) = @_;
            (grep { $_ == $dependent_int} @$constraining_arrayref) ? undef:1
        },
        ArrayRef[Int],
      ],
	  where {
		my ($dependent_val, $constraining_value) = @$_;
		return $dependent_val > 2 ? 1:undef;
	  };
      
    isa_ok UniqueInt, 'MooseX::Meta::TypeConstraint::Dependent';
    ok !UniqueInt->check(['a',[1,2,3]]), '"a" not an Int';
    ok !UniqueInt->check([1,['b','c']]), '"b","c" not an arrayref';    
    ok !UniqueInt->check([1,[1,2,3]]), 'not unique in set';
    ok !UniqueInt->check([10,[1,10,15]]), 'not unique in set';
    ok !UniqueInt->check([2,[3..6]]), 'FAIL dependent is too small';
    ok UniqueInt->check([3,[100..110]]), 'PASS unique in set';
    ok UniqueInt->check([4,[100..110]]), 'PASS unique in set';	
	
	## Basically as above, with sugar.
    subtype UniqueInt2,
	  as depending {
            my ($dependent_int, $constraining_arrayref) = @_;
            (grep { $_ == $dependent_int} @$constraining_arrayref) ? undef:1		
	  } Int, ArrayRef[Int],
	  where {
		my ($dependent_val, $constraining_value) = @$_;
		return $dependent_val > 2 ? 1:undef;
	  };

    isa_ok UniqueInt2, 'MooseX::Meta::TypeConstraint::Dependent';
    ok !UniqueInt2->check(['a',[1,2,3]]), '"a" not an Int';
    ok !UniqueInt2->check([1,['b','c']]), '"b","c" not an arrayref';    
    ok !UniqueInt2->check([1,[1,2,3]]), 'not unique in set';
    ok !UniqueInt2->check([10,[1,10,15]]), 'not unique in set';
    ok !UniqueInt2->check([2,[3..6]]), 'FAIL dependent is too small';
    ok UniqueInt2->check([3,[100..110]]), 'PASS unique in set';
    ok UniqueInt2->check([4,[100..110]]), 'PASS unique in set';	
}
