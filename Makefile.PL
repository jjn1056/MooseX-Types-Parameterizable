 
use strict;
use warnings;
use inc::Module::Install;

name 'MooseX-Dependent';
all_from 'lib/MooseX/Dependent.pm';
author 'John Napiorkowski <jjnapiork@cpan.org>';
repository 'git://jules.scsys.co.uk/gitmo/MooseX-Dependent.git';
license 'perl';

requires 'Moose' => '0.79';
requires 'MooseX::Types' => '0.10';
requires 'Scalar::Util' => '1.19';
requires 'Devel::PartialDump' => '0.07';

build_requires 'Test::More' => '0.86';

auto_install;
tests_recursive;
WriteAll;

package MY;

sub postamble {
    return "README:\tpod2text \$< > \$@";
}
