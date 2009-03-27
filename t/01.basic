use Test::More tests=>5;
use MooseX::Types::Structured qw(Tuple slurpy);
use MooseX::Types qw(Str Object);

use_ok 'MooseX::Meta::TypeConstraint::Structured';
use_ok 'Moose::Util::TypeConstraints';

ok my $int = find_type_constraint('Int') => 'Got Int';
ok my $str = find_type_constraint('Str') => 'Got Str';
ok my $obj = find_type_constraint('Object') => 'Got Object';
ok my $arrayref = find_type_constraint('ArrayRef') => 'Got ArrayRef';

my $a = [1,2,3,4];


package Dependent;

use overload(
	'&{}' => sub {
		warn 'sdfsdfsdfsdfsdf';
		return sub {};
 	},
);

sub new {
	my $class = shift @_;
	return bless {a=>1}, $class;
}

1;

my $dependent = Dependent->new($int);

$dependent->();

