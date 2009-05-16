use inc::Module::Install;

## All the required meta information
name 'MooseX-Dependent';
all_from 'lib/MooseX/Dependent.pm';
abstract 'Moose extensions to let you use dependent types in your classes';
author 'John Napiorkowski <jjnapiork@cpan.org>';
license 'perl';

## Module dependencies
requires 'Moose' => '0.73';
requires 'MooseX::Types' => '0.10';
requires 'Scalar::Util' => '1.19';
requires 'Devel::PartialDump' => '0.07';

## Testing dependencies
build_requires 'Test::More' => '0.70';
build_requires 'Test::Exception' => '0.27';
build_requires 'Test::Pod' => '1.14';
build_requires 'Test::Pod::Coverage' => '1.08';

## Build README
system 'pod2text lib/MooseX/Dependent.pm > README'
    if -e 'MANIFEST.SKIP';
    
## Instructions to Module::Install
auto_install;
tests_recursive;
WriteAll;

1;