
use strict;
use warnings;

use Test::More;
use MooseX::Types;
use MooseX::Types::Parameterizable qw(Parameterizable);
use MooseX::Types::Moose qw(Int Str);

ok my $varchar = (subtype as Parameterizable[Str, Int], where { $_[1] > length($_[0]); }),
  'Anonymous Type';

ok $varchar->parameterize(5)->check('aaa');
ok !$varchar->parameterize(5)->check('aaaaa');

done_testing;
