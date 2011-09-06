package Person;

use Moose;
use MooseX::Types::Parameterizable qw(Parameterizable);
use MooseX::Types::Moose qw(Int Str HashRef ArrayRef);
use MooseX::Types -declare=>[qw(
    InfoHash OlderThanAge2 DefinedOlderThanAge
)];

subtype( InfoHash,
as HashRef[Int],
where {
    defined $_->{older_than};
}),

subtype( OlderThanAge2,
as Parameterizable[Int, InfoHash],
where {
    my ($value, $dict) = @_;
    return $value > $dict->{older_than} ? 1:0;
});

coerce OlderThanAge2,
from HashRef,
via { 
    my ($hashref, $constraining_value) = @_;
    return scalar(keys(%$hashref));
},
from ArrayRef,
via { 
    my ($arrayref, $constraining_value) = @_;
    my $age;
    $age += $_ for @$arrayref;
    return $age;
};

has age=>(is=>'rw',isa=>OlderThanAge2[older_than=>2],coerce=>1);

use Test::More;

ok my $person = Person->new,
  'Created a testable object';
s
ok $person->age(3),
  '3 is older than 2';
is $person->age([1..10]), 55,
  'Coerce ArrayRef works';
is $person->age({a=>5,b=>6,c=>7,d=>8}), 4,
  'Coerce HashRef works';

done_testing;
