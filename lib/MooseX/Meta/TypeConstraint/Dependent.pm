package ## Hide from PAUSE
 MooseX::Meta::TypeConstraint::Dependent;

use Moose;
use Moose::Util::TypeConstraints ();
use MooseX::Meta::TypeCoercion::Dependent;
extends 'Moose::Meta::TypeConstraint';

=head1 NAME

MooseX::Meta::TypeConstraint::Dependent - Metaclass for Dependent type constraints.

=head1 DESCRIPTION

see L<MooseX::Types::Dependent> for examples and details of how to use dependent
types.  This class is a subclass of L<Moose::Meta::TypeConstraint> which
provides the gut functionality to enable dependent type constraints.

=head1 ATTRIBUTES

This class defines the following attributes.

=head2 dependent_type_constraint

The type constraint whose validity is being made dependent on a value that is a
L</constraining_type_constraint>

=cut

has 'dependent_type_constraint' => (
    is=>'ro',
    isa=>'Object',
    predicate=>'has_dependent_type_constraint',
    required=>1,
    handles=>{
        check_dependent=>'check',  
    },
);

=head2 constraining_type_constraint

This is a type constraint which defines what kind of value is allowed to be the
constraining value of the depending type.

=cut

has 'constraining_type_constraint' => (
    is=>'ro',
    isa=>'Object',
    predicate=>'has_constraining_type_constraint',
    required=>1,
    handles=>{
        check_constraining=>'check',  
    },
);

=head2 comparison_callback

This is a callback which returns a boolean value.  It get's passed the value
L</constraining_type_constraint> validates as well as the check value.

This callback is executed in addition to anything you put into a 'where' clause.
However, the 'where' clause only get's the check value.

Exercise some sanity, this should be limited to actual comparision operations,
not as a sneaky way to mess with the constraining value.

=cut

has 'comparison_callback' => (
    is=>'ro',
    isa=>'CodeRef',
    predicate=>'has_comparison_callback',
    required=>1,
);

=head2 constraint_generator

A subref or closure that contains the way we validate incoming values against
a set of type constraints.

=cut

has 'constraint_generator' => (
    is=>'ro',
    isa=>'CodeRef',
    predicate=>'has_constraint_generator',
    required=>1,
);

=head1 METHODS

This class defines the following methods.

=head2 new

Initialization stuff.

=cut

around 'new' => sub {
    my ($new, $class, @args)  = @_;
    my $self = $class->$new(@args);
    $self->coercion(MooseX::Meta::TypeCoercion::Dependent->new(
        type_constraint => $self,
    ));
    return $self;
};

=head2 check($check_value, $constraining_value)

Make sure when properly dispatch all the right values to the right spots

=cut

around 'check' => sub {
    my ($check, $self, $check_value, $constraining_value) = @_;
    
    unless($self->check_dependent($check_value)) {
        return;
    }

    unless($self->check_constraining($constraining_value)) {
        return;
    }

    return $self->$check($check_value, $constraining_value);
};

=head2 generate_constraint_for ($type_constraints)

Given some type constraints, use them to generate validation rules for an ref
of values (to be passed at check time)

=cut

sub generate_constraint_for {
    my ($self, $callback, $constraining) = @_;
    return sub {   
        my ($check_value, $constraining_value) = @_;
        my $constraint_generator = $self->constraint_generator;
        return $constraint_generator->(
            $callback,
            $check_value,
            $constraining_value,
        );
    };
}

=head2 parameterize ($dependent, $callback, $constraining)

Given a ref of type constraints, create a structured type.

=cut

sub parameterize {
    my ($self, $dependent, $callback, $constraining) = @_;
    my $class = ref $self;
    my $name = $self->_generate_subtype_name($dependent,  $callback, $constraining);
    my $constraint_generator = $self->__infer_constraint_generator;

    return $class->new(
        name => $name,
        parent => $self,
        dependent_type_constraint=>$dependent,
        comparison_callback=>$callback,
        constraint_generator => $constraint_generator,
        constraining_type_constraint => $constraining,
    );
}

=head2 _generate_subtype_name

Returns a name for the dependent type that should be unique

=cut

sub _generate_subtype_name {
    my ($self, $dependent, $callback, $constraining) = @_;
    return sprintf(
        "%s_depends_on_%s_via_%s",
        $dependent, $constraining, $callback
    );
}

=head2 __infer_constraint_generator

This returns a CODEREF which generates a suitable constraint generator.  Not
user servicable, you'll never call this directly.

    TBD, this is definitely going to need some work.

=cut

sub __infer_constraint_generator {
    my ($self) = @_;
    if($self->has_constraint_generator) {
        return $self->constraint_generator;
    } else {
        return sub {
            ## I'm not sure about this stuff but everything seems to work
            my $tc = shift @_;
            my $merged_tc = [
                @$tc,
                $self->comparison_callback,
                $self->constraining_type_constraint,
            ];
            
            $self->constraint->($merged_tc, @_);            
        };
    }    
}

=head2 compile_type_constraint

hook into compile_type_constraint so we can set the correct validation rules.

=cut

around 'compile_type_constraint' => sub {
    my ($compile_type_constraint, $self) = @_;
    
    if($self->has_comparison_callback &&
        $self->has_constraining_type_constraint) {
        my $generated_constraint = $self->generate_constraint_for(
            $self->comparison_callback,
             $self->constraining_type_constraint,
        );
        $self->_set_constraint($generated_constraint);       
    }

    return $self->$compile_type_constraint;
};

=head2 create_child_type

modifier to make sure we get the constraint_generator

around 'create_child_type' => sub {
    my ($create_child_type, $self, %opts) = @_;
    return $self->$create_child_type(
        %opts,
        constraint_generator => $self->__infer_constraint_generator,
    );
};

=head2 is_a_type_of

=head2 is_subtype_of

=head2 equals

Override the base class behavior.

    TBD

sub equals {
    my ( $self, $type_or_name ) = @_;
    my $other = Moose::Util::TypeConstraints::find_type_constraint($type_or_name);

    return unless $other->isa(__PACKAGE__);
    
    return (
        $self->type_constraints_equals($other)
            and
        $self->parent->equals( $other->parent )
    );
}

=head2 type_constraints_equals

Checks to see if the internal type contraints are equal.

    TBD

sub type_constraints_equals {
    my ($self, $other) = @_;
    my @self_type_constraints = @{$self->type_constraints||[]};
    my @other_type_constraints = @{$other->type_constraints||[]};
    
    ## Incoming ay be either arrayref or hashref, need top compare both
    while(@self_type_constraints) {
        my $self_type_constraint = shift @self_type_constraints;
        my $other_type_constraint = shift @other_type_constraints
         || return; ## $other needs the same number of children.
        
        if( ref $self_type_constraint) {
            $self_type_constraint->equals($other_type_constraint)
             || return; ## type constraints obviously need top be equal
        } else {
            $self_type_constraint eq $other_type_constraint
             || return; ## strings should be equal
        }

    }
    
    return 1; ##If we get this far, everything is good.
}

=head2 get_message

Give you a better peek into what's causing the error.  For now we stringify the
incoming deep value with L<Devel::PartialDump> and pass that on to either your
custom error message or the default one.  In the future we'll try to provide a
more complete stack trace of the actual offending elements

    TBD

around 'get_message' => sub {
    my ($get_message, $self, $value) = @_;
    my $new_value = Devel::PartialDump::dump($value);
    return $self->$get_message($new_value);
};

=head1 SEE ALSO

The following modules or resources may be of interest.

L<Moose>, L<Moose::Meta::TypeConstraint>

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
