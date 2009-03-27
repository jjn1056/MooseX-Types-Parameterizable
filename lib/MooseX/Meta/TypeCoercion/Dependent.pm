package ## Hide from PAUSE
 MooseX::Meta::TypeCoercion::Dependent;

use Moose;
extends 'Moose::Meta::TypeCoercion';

=head1 NAME

MooseX::Meta::TypeCoercion::Dependent - Coerce structured type constraints.

=head1 DESCRIPTION

TBD

=head1 METHODS

This class defines the following methods.

=head1 SEE ALSO

The following modules or resources may be of interest.

L<Moose>, L<Moose::Meta::TypeCoercion>

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;