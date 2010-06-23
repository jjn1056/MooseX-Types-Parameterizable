 
use strict;
use warnings;
use inc::Module::Install 1.00;

name 'MooseX-Types-Parameterizable';
all_from 'lib/MooseX/Types/Parameterizable.pm';
author 'John Napiorkowski <jjnapiork@cpan.org>';
repository 'git://github.com/jjn1056/MooseX-Types-Parameterizable.git';
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

