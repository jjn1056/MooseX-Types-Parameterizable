package MooseX::Dependent;

use 5.008;

use strict;
use warnings;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:JJNAPIORK';

=head1 NAME

MooseX::Dependent - Dependent L<MooseX::Types> constraints and L<Moose> attributes

=head1 SYNOPSIS

Given some L<MooseX::Types> declared as:

    package MyApp::Types;
    
    use MooseX::Types::Moose qw(Object, Int);
    use MooseX::Dependent::Types qw(Dependent);
    use Moosex::Types -declare => [qw(Set UniqueID)];

	subtype Set,
		as Object,
		where {
		    shift->can('find');
		};

	subtype UniqueID,
		as Dependent[Int, Set],
		where {
		    my ($int, $set) = @_;
		    return $set->find($int) ? 0:1;
		};

Assuming 'Set' is a class that creates and manages sets of values (lists of
unique but unordered values) with a method '->find($n)', which returns true when
$n is a member of the set and which you instantiate like so:

    my $set_obj = Set->new(1,2,3,4,5); ## 1..5 are member of Set $set_obj'

You can then use this $set_obj as a parameter on the previously declared type
constraint 'UniqueID'.  This $set_obj become part of the constraint (you can't
actually use the constraint without it.)

    UniqueID[$set_obj]->check(1); ## Not OK, since one isn't unique in $set_obj
    UniqueID[$set_obj]->check(100); ## OK, since 100 isn't in the set.
    
You can assign the result of a parameterized dependent type to a variable or to
another type constraint, as like any other type constraint:

    ## As variable
    my $unique = UniqueID[$set_obj];
    $unique->check(10); ## OK
    $unique->check(2); ## Not OK, '2' is already in the set.
    
    ## As a new subtype
    subtype UniqueInSet, as UniqueID[$set_obj];
    UniqueInSet->check(99); ## OK
    UniqueInSet->check(3); ## Not OK, '3' is already in the set.
    
However, you can't use a dependent type constraint to check or validate a value
until you've parameterized the dependent value:

    UniqueID->check(1000); ## Throws exception
    UniqueID->validate(1000); ## Throws exception also
    
This is a hard exception, rather than just returning a failure message (via the
validate method) or a false boolean (via the check method) since I consider an
unparameterized type constraint to be more than just an invalid condition.  You
will have to catch these in an eval if you think you might have them.

Afterward, you can use these dependent types on your L<Moose> based classes
and set the dependency target to the value of another attribute or method:

    TDB: Following is tentative
    
    package MyApp::MyClass;

    use Moose;
    use MooseX::Dependent (or maybe a role, or traits...?)
    use MooseX::Types::Moose qw();
    use MyApp::Types qw(UniqueID Set);
    
    has people => (is=>'ro', isa=>Set, required=>1);
    has id => (is=>'ro', dependent_isa=>UniqueID, required=>1);

Please see the test cases for more examples.

=head1 DESCRIPTION

A dependent type is a type constraint whose validity is dependent on a second
value.  You defined the dependent type constraint with a primary type constraint
(such as 'Int') a 'constraining' value type constraint (such as a 'Set' object)
and a coderef (such as a 'where' clause in your type constraint declaration)
which will compare the incoming value to be checked with a value that conforms
to the constraining type constraint.

Once created, you can use dependent types directly, or in your L<Moose> based
attributes and methods (if you are using L<MooseX::Declare>).  Attribute traits
are available to make it easy to assign the dependency to the value of another
attribute or another method.

=head1 TYPE CONSTRAINTS

All type constraints are defined in L<MooseX::Dependent::Types>.  Please see
that class for more documentation and examples of how to create type constraint
libraries using dependent types.

=cut

=head1 ATTRIBUTE TRAITS

    TBD

=head1 SEE ALSO

L<Moose>, L<Moose::Meta::TypeConstraints>, L<MooseX::Types>

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
