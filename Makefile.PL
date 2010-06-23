 
use strict;
use warnings;
use inc::Module::Install 1.00;

name 'MooseX-Dependent';
all_from 'lib/MooseX/Dependent.pm';
author 'John Napiorkowski <jjnapiork@cpan.org>';
repository 'git://git.moose.perl.org/MooseX-Dependent.git'

license 'perl';

requires 'Moose' => '1.08';
requires 'MooseX::Types' => '0.22';
requires 'Scalar::Util' => '1.19';
requires 'Devel::PartialDump' => '0.13';
requires 'Data::Dump' => '1.17';
requires 'Digest::MD5' => '2.39';

build_requires 'Test::More' => '0.94';
build_requires 'Test::Exception' => '0.29';

auto_install;
tests_recursive;
WriteAll;

