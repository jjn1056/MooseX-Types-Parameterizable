
use Test::More tests=>4; {
    
    use strict;
    use warnings;
    
    ## List all the modules we want to make sure can at least compile
    use_ok 'MooseX::Dependent';
    use_ok 'MooseX::Dependent::Types';
    use_ok 'MooseX::Dependent::Meta::TypeConstraint::Dependent';
    use_ok 'MooseX::Dependent::Meta::TypeCoercion::Dependent';
}

