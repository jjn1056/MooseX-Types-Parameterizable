package ## Hide from PAUSE
 MooseX::Dependent::Meta::TypeConstraint::Dependent;

use Moose;
use Moose::Util::TypeConstraints ();
extends 'Moose::Meta::TypeConstraint';

=head1 NAME

MooseX::Dependent::Meta::TypeConstraint::Dependent - Metaclass for Dependent type constraints.

=head1 DESCRIPTION

see L<MooseX::Dependent> for examples and details of how to use dependent
types.  This class is a subclass of L<Moose::Meta::TypeConstraint> which
provides the gut functionality to enable dependent type constraints.

=head1 ATTRIBUTES

This class defines the following attributes.

=head2 parent_type_constraint

The type constraint whose validity is being made dependent.

=cut

has 'parent_type_constraint' => (
    is=>'ro',
    isa=>'Object',
    predicate=>'has_parent_type_constraint',
    default=> sub {
        Moose::Util::TypeConstraints::find_type_constraint("Any");
    },
    required=>1,
);

=head2 constraining_value_type_constraint

This is a type constraint which defines what kind of value is allowed to be the
constraining value of the dependent type.

=cut

has 'constraining_value_type_constraint' => (
    is=>'ro',
    isa=>'Object',
    predicate=>'has_constraining_value_type_constraint',
    default=> sub {
        Moose::Util::TypeConstraints::find_type_constraint("Any");
    },
    required=>1,
);

=head2 constrainting_value

This is the actual value that constraints the L</parent_type_constraint>

=cut

has 'constraining_value' => (
    reader=>'constraining_value',
    writer=>'_set_constraining_value',
    predicate=>'has_constraining_value',
);

=head2 constraint_generator

A subref or closure that contains the way we validate incoming values against
a set of type constraints.


has 'constraint_generator' => (
    is=>'ro',
    isa=>'CodeRef',
    predicate=>'has_constraint_generator',
    required=>1,
);

=head1 METHODS

This class defines the following methods.

=head2 validate

We intercept validate in order to custom process the message.

override 'validate' => sub {
    my ($self, @args) = @_;
    my $compiled_type_constraint = $self->_compiled_type_constraint;
    my $message = bless {message=>undef}, 'MooseX::Types::Dependent::Message';
    my $result = $compiled_type_constraint->(@args, $message);

    if($result) {
        return $result;
    } else {
        my $args = Devel::PartialDump::dump(@args);
        if(my $message = $message->{message}) {
            return $self->get_message("$args, Internal Validation Error is: $message");
        } else {
            return $self->get_message($args);
        }
    }
};

=head2 generate_constraint_for ($type_constraints)

Given some type constraints, use them to generate validation rules for an ref
of values (to be passed at check time)


sub generate_constraint_for {
    my ($self, $callback) = @_;
    return sub {   
        my $dependent_pair = shift @_;
        my ($dependent, $constraining) = @$dependent_pair;
        
        ## First need to test the bits
        unless($self->check_dependent($dependent)) {
            $_[0]->{message} = $self->get_message_dependent($dependent)
             if $_[0];
            return;
        }
    
        unless($self->check_constraining($constraining)) {
            $_[0]->{message} = $self->get_message_constraining($constraining)
             if $_[0];
            return;
        }
    
        my $constraint_generator = $self->constraint_generator;
        return $constraint_generator->(
            $dependent,
            $callback,
            $constraining,
        );
    };
}

=head2 parameterize ($dependent, $callback, $constraining)

Given a ref of type constraints, create a structured type.

=cut

sub parameterize {
    my ($self, $dependent_tc, $callback, $constraining_tc) = @_;
    
    die 'something';
    
    my $class = ref $self;
    my $name = $self->_generate_subtype_name($dependent_tc,  $callback, $constraining_tc);
    my $constraint_generator = $self->__infer_constraint_generator;

    return $class->new(
        name => $name,
        parent => $self,
        dependent_type_constraint=>$dependent_tc,
        comparison_callback=>$callback,
        constraint_generator => $constraint_generator,
        constraining_type_constraint => $constraining_tc,
    );
}

=head2 _generate_subtype_name

Returns a name for the dependent type that should be unique

=cut

sub _generate_subtype_name {
    my ($self, $parent_tc, $constraining_tc) = @_;
    return sprintf(
        "%s_depends_on_%s",
        $parent_tc, $constraining_tc,
    );
}

=head2 __infer_constraint_generator

This returns a CODEREF which generates a suitable constraint generator.  Not
user servicable, you'll never call this directly.

    TBD, this is definitely going to need some work.  Cargo culted from some
    code I saw in Moose::Meta::TypeConstraint::Parameterized or similar.  I
    Don't think I need this, since Dependent types require parameters, so
    will always have a constrain generator.

=cut

sub __infer_constraint_generator {
    my ($self) = @_;
    if($self->has_constraint_generator) {
        return $self->constraint_generator;
    } else {
        warn "I'm doing the questionable infer generator thing";
        return sub {
            ## I'm not sure about this stuff but everything seems to work
            my $tc = shift @_;
            my $merged_tc = [
                @$tc,
            ];
            
            $self->constraint->($merged_tc, @_);            
        };
    }    
}

=head2 compile_type_constraint

hook into compile_type_constraint so we can set the correct validation rules.



around 'compile_type_constraint' => sub {
    my ($compile_type_constraint, $self) = @_;
    
    if($self->has_comparison_callback &&
        $self->has_constraining_type_constraint) {
        my $generated_constraint = $self->generate_constraint_for(
            $self->comparison_callback,
        );
        $self->_set_constraint($generated_constraint);
    }

    return $self->$compile_type_constraint;
};

=head2 create_child_type

modifier to make sure we get the constraint_generator

=cut

around 'create_child_type' => sub {
    my ($create_child_type, $self, %opts) = @_;
    return $self->$create_child_type(
        %opts,
        #constraint_generator => $self->__infer_constraint_generator,
    );
};

=head2 equals

Override the base class behavior.

sub equals {
    my ( $self, $type_or_name ) = @_;
    my $other = Moose::Util::TypeConstraints::find_type_constraint("$type_or_name");

    return (
        $other->isa(__PACKAGE__)
            and
        $self->dependent_type_constraint->equals($other)
            and
        $self->constraining_type_constraint->equals($other)
            and 
        $self->parent->equals($other->parent)
    );
}

=head2 get_message

Give you a better peek into what's causing the error.

around 'get_message' => sub {
    my ($get_message, $self, $value) = @_;
    return $self->$get_message($value);
};

=head2 _throw_error ($error)

Given a string, delegate to the Moose exception object

=cut

sub _throw_error {
    my $self = shift @_;
    my $err = defined $_[0] ? $_[0] : 'Exception Thrown without Message';
    require Moose; Moose->throw_error($err);
}

=head1 SEE ALSO

The following modules or resources may be of interest.

L<Moose>, L<Moose::Meta::TypeConstraint>

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

