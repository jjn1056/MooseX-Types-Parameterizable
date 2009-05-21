package ## Hide from PAUSE
 MooseX::Dependent::Meta::TypeConstraint::Dependent;

use Moose;
use Moose::Util::TypeConstraints ();
use Scalar::Util qw(blessed);

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
    default=> sub {
        Moose::Util::TypeConstraints::find_type_constraint("Any");
    },
    required=>1,
);

=head2 constraining_value

This is the actual value that constraints the L</parent_type_constraint>

=cut

has 'constraining_value' => (
    is=>'ro',
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

=head2 parameterize (@args)

Given a ref of type constraints, create a structured type.
    
=cut

sub parameterize {
    my $self = shift @_;
    my $class = ref $self;
    
    if(blessed $_[0] && $_[0]->isa('Moose::Meta::TypeConstraint')) {
        my $arg1 = shift @_;
        my $arg2 = shift @_ || $self->constraining_value_type_constraint;
        
        Moose->throw_error("$arg2 is not a type constraint")
         unless $arg2->isa('Moose::Meta::TypeConstraint');
         
        Moose->throw_error('Too Many Args!  Two are allowed.') if @_;
        
        return $class->new(
            name => $self->_generate_subtype_name($arg1, $arg2),
            parent => $self,
            constraint => $self->constraint,
            parent_type_constraint=>$arg1,
            constraining_value_type_constraint => $arg2,
        );

    } else {
        Moose->throw_error("$self already has a constraining value.") if
         $self->has_constraining_value;
        
        my $args;
        ## Jump through some hoops to let them do tc[key=>10] and tc[{key=>10}]
        if(@_) {
            if($#_) {
                if($self->constraining_value_type_constraint->is_a_type_of('HashRef')) {
                    $args = {@_};
                } else {
                    $args = [@_];
                }                
            } else {
                $args = $_[0];
            }

        } else {
            ## TODO:  Is there a use case for parameterizing null or undef?
            Moose->throw_error('Cannot Parameterize null values.');
        }
        
        if(my $err = $self->constraining_value_type_constraint->validate($args)) {
            Moose->throw_error($err);
        } else {
            ## TODO memorize or do a registry lookup on the name as an optimization
            return $class->new(
                name => $self->name."[$args]",
                parent => $self,
                constraint => $self->constraint,
                constraining_value => $args,
                parent_type_constraint=>$self->parent_type_constraint,
                constraining_value_type_constraint => $self->constraining_value_type_constraint,
            );            
        }
    } 
}

=head2 _generate_subtype_name

Returns a name for the dependent type that should be unique

=cut

sub _generate_subtype_name {
    my ($self, $parent_tc, $constraining_tc) = @_;
    return sprintf(
        $self."[%s, %s]",
        $parent_tc, $constraining_tc,
    );
}

=head2 create_child_type

modifier to make sure we get the constraint_generator

=cut

around 'create_child_type' => sub {
    my ($create_child_type, $self, %opts) = @_;
    return $self->$create_child_type(
        %opts,
        parent=> $self,
        parent_type_constraint=>$self->parent_type_constraint,
        constraining_value_type_constraint => $self->constraining_value_type_constraint,
    );
};

=head2 equals ($type_constraint)

Override the base class behavior so that a dependent type equal both the parent
type and the overall dependent container.  This behavior may change if we can
figure out what a dependent type is (multiply inheritance or a role...)

=cut

around 'equals' => sub {
    my ( $equals, $self, $type_or_name ) = @_;
    
    my $other = defined $type_or_name ?
      Moose::Util::TypeConstraints::find_type_constraint($type_or_name) :
      Moose->throw_error("Can't call $self ->equals without a parameter");
      
    Moose->throw_error("$type_or_name is not a registered Type")
     unless $other;
     
    if(my $parent = $other->parent) {
        return $self->$equals($other)
         || $self->parent->equals($parent);        
    } else {
        return $self->$equals($other);
    }
};

around 'is_subtype_of' => sub {
    my ( $is_subtype_of, $self, $type_or_name ) = @_;

    my $other = defined $type_or_name ?
      Moose::Util::TypeConstraints::find_type_constraint($type_or_name) :
      Moose->throw_error("Can't call $self ->equals without a parameter");
      
    Moose->throw_error("$type_or_name is not a registered Type")
     unless $other;
     
    return $self->$is_subtype_of($other)
        || $self->parent_type_constraint->is_subtype_of($other);

};

sub is_a_type_of {
    my ($self, @args) = @_;
    return ($self->equals(@args) ||
      $self->is_subtype_of(@args));
}

around 'check' => sub {
    my ($check, $self, @args) = @_;
    if($self->has_constraining_value) {
        push @args, $self->constraining_value;
    }
    return $self->parent_type_constraint->check(@args) && $self->$check(@args)
};

around 'validate' => sub {
    my ($validate, $self, @args) = @_;
    if($self->has_constraining_value) {
        push @args, $self->constraining_value;
    }
    return $self->parent_type_constraint->validate(@args) || $self->$validate(@args);
};

=head2 get_message

Give you a better peek into what's causing the error.

around 'get_message' => sub {
    my ($get_message, $self, $value) = @_;
    return $self->$get_message($value);
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

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

