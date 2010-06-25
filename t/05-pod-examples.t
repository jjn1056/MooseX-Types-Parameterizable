use strict;
use warnings;

use Test::More;

{
    package Test::MooseX::Types::Parameterizable::Synopsis;

    use Moose;
    use MooseX::Types::Parameterizable qw(Parameterizable);
    use MooseX::Types::Moose qw(Str Int ArrayRef);
    use MooseX::Types -declare=>[qw(Varchar)];

    subtype Varchar,
      as Parameterizable[Str,Int],
      where {
        my($string, $int) = @_;
        $int >= length($string) ? 1:0;
      },
      message { "'$_' is too long"  };

    coerce Varchar,
      from ArrayRef,
      via { 
        my ($arrayref, $int) = @_;
        join('', @$arrayref);
      };

    my $varchar_five = Varchar[5];

    Test::More::ok $varchar_five->check('four');
    Test::More::ok ! $varchar_five->check('verylongstrong');

    my $varchar_ten = Varchar[10];

    Test::More::ok $varchar_ten->check( 'X' x 9 );
    Test::More::ok ! $varchar_ten->check( 'X' x 12 );

    has varchar_five => (isa=>Varchar[5], is=>'ro', coerce=>1);
    has varchar_ten => (isa=>Varchar[10], is=>'ro');
  
    my $object1 = __PACKAGE__->new(
        varchar_five => '1234',
        varchar_ten => '123456789',
    );

    eval {
        my $object2 = __PACKAGE__->new(
            varchar_five => '12345678',
            varchar_ten => '123456789',
        );
    };

    Test::More::ok $@, 'There was an error';
    Test::More::like $@, qr('12345678' is too long), 'Correct custom error';

    my $object3 = __PACKAGE__->new(
        varchar_five => [qw/aa bb/],
        varchar_ten => '123456789',
    );

    Test::More::is $object3->varchar_five, 'aabb',
      'coercion as expected';
}

{
    package Test::MooseX::Types::Parameterizable::Description;

    use Moose;
    use MooseX::Types::Parameterizable qw(Parameterizable);
    use MooseX::Types::Moose qw(HashRef Int);
    use MooseX::Types -declare=>[qw(Range RangedInt)];

    ## Minor change from docs to avoid additional test dependencies
    subtype Range,
        as HashRef[Int],
        where {
            my ($range) = @_;
            return $range->{max} > $range->{min};
        },
        message { "Not a Valid range [ $_->{max} not > $_->{min} ] " };

    subtype RangedInt,
        as Parameterizable[Int, Range],
        where {
            my ($value, $range) = @_;
            return ($value >= $range->{min} &&
             $value <= $range->{max});
        };
        
    Test::More::ok RangedInt([{min=>10,max=>100}])->check(50);
    Test::More::ok !RangedInt([{min=>50, max=>75}])->check(99);

    eval {
        Test::More::ok !RangedInt([{min=>99, max=>10}])->check(10); 
    }; 

    Test::More::ok $@, 'There was an error';
    Test::More::like $@, qr(Not a Valid range), 'Correct custom error';

    Test::More::ok RangedInt([min=>10,max=>100])->check(50);
    Test::More::ok ! RangedInt([min=>50, max=>75])->check(99);

    eval {
        RangedInt([min=>99, max=>10])->check(10); 
    }; 

    Test::More::ok $@, 'There was an error';
    Test::More::like $@, qr(Not a Valid range), 'Correct custom error';


}


done_testing;


__END__

use MooseX::Types -declare=>[qw(Set UniqueInt PositiveSet PositiveUniqueInt )];

subtype Set,
  as class_type("Set::Scalar");

subtype UniqueInt,
  as Parameterizable[Int, Set],
  where {
    my ($int, $set) = @_;
    !$set->has($int);
  };

subtype PositiveSet,
  as Set,
  where {
    my ($set) = @_;
    ! grep { $_ < 0 } $set->members;
  };
  
subtype PositiveUniqueInt,
  as UniqueInt[PositiveSet];

my $set = Set::Scalar->new(-1,-2,1,2,3);
my $positive_set = Set::Scalar->new(1,2,3);
my $negative_set = Set::Scalar->new(-1,-2,-3);

ok Set->check($set),
 'Is a Set';

ok Set->check($positive_set),
 'Is a Set';

ok Set->check($negative_set),
 'Is a Set';

ok !PositiveSet->check($set),
 'Is Not a Positive Set';

ok PositiveSet->check($positive_set),
 'Is a Positive Set';

ok !PositiveSet->check($negative_set),
 'Is Not a Positive Set';

ok UniqueInt([$set])->check(100),
 '100 not in Set';

ok UniqueInt([$positive_set])->check(100),
 '100 not in Set';

ok UniqueInt([$negative_set])->check(100),
 '100 not in Set';

ok UniqueInt([$set])->check(-99),
 '-99 not in Set';

ok UniqueInt([$positive_set])->check(-99),
 '-99 not in Set';

ok UniqueInt([$negative_set])->check(-99),
  '-99 not in Set';

ok !UniqueInt([$set])->check(2),
 '2 in Set';

ok !UniqueInt([$positive_set])->check(2),
 '2 in Set';

ok UniqueInt([$negative_set])->check(2),
  '2 not in Set';


__END__

ok UniqueInt([$set])->check(100);  ## Okay, 100 isn't in (1,2,3)
ok UniqueInt([$set])->check(-99);  ## Okay, -99 isn't in (1,2,3)
ok !UniqueInt([$set])->check(2);  ## Not OK, 2 is in (1,2,3)

ok PositiveUniqueInt([$set])->check(100);  ## Okay, 100 isn't in (1,2,3)
ok !PositiveUniqueInt([$set])->check(-99);  ## Not OK, -99 not Positive Int
ok !PositiveUniqueInt([$set])->check(2);  ## Not OK, 2 is in (1,2,3)

my $negative_set = Set::Scalar->new(-1,-2,-3);

ok UniqueInt([$negative_set])->check(100);  ## Throws exception

