
use Test::More tests=>9; {
	
	use strict;
	use warnings;

	use MooseX::Dependent::Types qw(Dependent);
	use MooseX::Types::Moose qw(Int Str HashRef ArrayRef);
	
	use MooseX::Types -declare=>[qw(
		InfoHash OlderThanAge
	)];
	
	ok subtype( InfoHash,
		as HashRef[Int],
		where {
			defined $_->{older_than};
		}), 'Created InfoHash Set (reduce need to depend on Dict type';

	ok InfoHash->check({older_than=>25}), 'Good InfoHash';
	ok !InfoHash->check({older_than=>'aaa'}), 'Bad InfoHash';
	ok !InfoHash->check({at_least=>25}), 'Bad InfoHash';
	
	ok subtype( OlderThanAge,
		as Dependent[Int, InfoHash],
		where {
			my ($value, $dict) = @_;
			return $value > $dict->{older_than} ? 1:0;
		}), 'Created the OlderThanAge subtype';
	
	ok OlderThanAge([{older_than=>25}])->check(39), '39 is older than 25';
	ok OlderThanAge([older_than=>1])->check(9), '9 is older than 1';
	ok !OlderThanAge([older_than=>1])->check('aaa'), '"aaa" not an int';
	ok !OlderThanAge([older_than=>10])->check(9), '9 is not older than 10';
	
	coerce OlderThanAge,
		from ArrayRef,
		via {
			my ($arrayref, $constraining_value) = @_;
			my $age;
			$age += $_ for @$arrayref;
			return $age;
		};
		
	#warn OlderThanAge([older_than=>1])->coerce([1,2,3,4]);
}