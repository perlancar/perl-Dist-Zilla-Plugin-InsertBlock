package Dist::Zilla::Plugin::InsertBlock::FromModule;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Module::Path::More qw(module_path);

use parent qw(Dist::Zilla::Plugin::InsertBlock);

sub _insert_block {
    my($self, $module, $name) = @_;

    my $file = module_path(module=>$module) or
        $log->log_fatal(["can't find path for module %s", $module]);

    $self->SUPER::_insert_block($file, $name);
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert a block of text from another module

=for Pod::Coverage .+

=head1 SYNOPSIS

In dist.ini:

 [InsertBlock::FromModule]

In lib/Foo/Bar.pm:

 ...

 =head1 ATTRIBUTES

 # INSERT_BLOCK: Foo::Base base_attributes

 =head2 attr3

 ...


=head1 DESCRIPTION

This plugin is just like L<Dist::Zilla::Plugin::InsertBlock>, but instead of
filename in the first argument, you specify module name. Module name will then
be converted into path using L<Module::Path::More>. Die when module path is not
found.


=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertBlock>
