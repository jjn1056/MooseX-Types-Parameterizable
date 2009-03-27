package MooseX::Types::Dependent;

use strict;
use warnings;


#use Carp::Clan qw( ^MooseX::Types );
use Moose::Util::TypeConstraints ();
use Scalar::Util qw(blessed);

use overload(
    '""' => sub {
    		my $self = shift @_;
    		if(blessed $self) {
        		return $self->__internal_type_constraint->name;     		
    		} else {
    			return "$self";
    		}
    },
    fallback => 1,
);

=head1 NAME

MooseX::Types::Dependent - Type Constraints that are dependent on others

=head1 SYNOPSIS

    use MooseX::Types::Dependent;
    
    ## Assuming the type constraint 'Set' isa Set::Scalar

    subtype UniqueInt,
      as Dependent[Int,Set],
      where {
        ## ok Set->check($set), 'Good $set';
        ## ok Int->check($val), 'Already an Int'
        my ($set, $val) = @_;
        ## If the $set already has $val, then it's not unique
        return $set->has($val) ? 0:1
      };
      
    my $set = Set::Scalar->new(1..10);
    
    ok UniqueInt->check([1, $set]);  ## Fails, 1 is already in $set;
    ok UniqueInt->check(['a', $set]); ## Fails, 'a' is not an Int;
    ok UniqueInt->check([1, $obj]); ## Fails, $obj is not a Set;
    ok UniqueInt->check([20, $set]); ## PASSES

=head1 DESCRIPTION

This is a decorator object that contains an underlying type constraint.  We use
this to control access to the type constraint and to add some features.

=head1 METHODS

This class defines the following methods.

=head2 new

Old school instantiation

=cut

sub new {
    my $class = shift @_;
    my $attributes = {};
    if(my $
    if(my $arg = shift @_) {
        if(blessed $arg && $arg->isa('Moose::Meta::TypeConstraint')) {
            return bless {'__type_constraint'=>$arg}, $class;
        } elsif(
            blessed $arg &&
            $arg->isa('MooseX::Types::UndefinedType') 
          ) {
            ## stub in case we'll need to handle these types differently
            return bless {'__type_constraint'=>$arg}, $class;
        } elsif(blessed $arg) {
            croak "Argument must be ->isa('Moose::Meta::TypeConstraint') or ->isa('MooseX::Types::UndefinedType'), not ". blessed $arg;
        } else {
            croak "Argument cannot be '$arg'";
        }
    } else {
        croak "This method [new] requires a single argument.";        
    }
}

=head2 __internal_type_constraint ($type_constraint)

Set/Get the type_constraint we are making dependent.

=cut

sub __internal_type_constraint {
    my $self = shift @_;    
    if(blessed $self) {
        if(defined(my $tc = shift @_)) {
            $self->{__type_constraint} = $tc;
        }
        return $self->{__type_constraint};        
    } else {
        croak 'cannot call __internal_type_constraint as a class method';
    }
}

=head2 isa

handle $self->isa since AUTOLOAD can't.

=cut

sub isa {
    my ($self, $target) = @_;  
    if(defined $target) {
    	if(blessed $self) {
    		return $self->__internal_type_constraint->isa($target);
    	} else {
    		return;
    	}
    } else {
        return;
    }
}

=head2 can

handle $self->can since AUTOLOAD can't.

=cut

sub can {
    my ($self, $target) = @_;
    if(defined $target) {
    	if(blessed $self) {
    		return $self->__internal_type_constraint->can($target);
    	} else {
    		return;
    	}
    } else {
        return;
    }
}

=head2 meta

have meta examine the underlying type constraints

=cut

sub meta {
	my $self = shift @_;
	if(blessed $self) {
		return $self->__internal_type_constraint->meta;
	} 
}


=head2 DESTROY

We might need it later

=cut

sub DESTROY {
    return;
}

=head2 AUTOLOAD

Delegate to the decorator targe

=cut

sub AUTOLOAD {
    
    my ($self, @args) = @_;
    my ($method) = (our $AUTOLOAD =~ /([^:]+)$/);
    
    ## We delegate with this method in an attempt to support a value of
    ## __type_constraint which is also AUTOLOADing, in particular the class
    ## MooseX::Types::UndefinedType which AUTOLOADs during autovivication.
    
    my $return;
    
    eval {
        $return = $self->__internal_type_constraint->$method(@args);
    }; if($@) {
        croak $@;
    } else {
        return $return;
    }
}

=head1 AUTHOR AND COPYRIGHT

John Napiorkowski (jnapiorkowski) <jjnapiork@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

