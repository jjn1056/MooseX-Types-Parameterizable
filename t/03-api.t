use Test::More tests=>1; {
    
    use strict;
    use warnings;
    
    use Test::Exception;
    use MooseX::Types::Dependent qw(Depending);
 	use MooseX::Types::Moose qw(Int ArrayRef );
	use MooseX::Types -declare => [qw(
        UniqueInt
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
 
    ok subtype UniqueInt,
	  as depending {
            my ($dependent_int, $constraining_arrayref) = @_;
            (grep { $_ == $dependent_int} @$constraining_arrayref) ? undef:1		
	  } Int, ArrayRef[Int],
	  where {
		my ($dependent_val, $constraining_value) = @$_;
		return $dependent_val > 2 ? 1:undef;
	  };
}
