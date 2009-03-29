
use Test::More tests=>3; {
    
    use strict;
    use warnings;
    
    ## List all the modules we want to make sure can at least compile
    use_ok 'MooseX::Types::Dependent';
    use_ok 'MooseX::Meta::TypeConstraint::Dependent';
    use_ok 'MooseX::Meta::TypeCoercion::Dependent';
}

