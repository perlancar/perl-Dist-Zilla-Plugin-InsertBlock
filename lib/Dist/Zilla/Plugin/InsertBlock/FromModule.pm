package Dist::Zilla::Plugin::InsertBlock::FromModule;

use 5.010001;
use strict;
use warnings;

use Module::Path::More qw(module_path);

use parent qw(Dist::Zilla::Plugin::InsertBlock);

# AUTHORITY
# DATE
# DIST
# VERSION

sub BUILD {
    my $self = shift;

    if ($self->zilla->plugin_named('InsertBlock')) {
        # if user also loads InsertBlock plugin, use another directive so the
        # two don't clash
        $self->_directive_re(qr/INSERT_BLOCK_FROM_MODULE/);
    } else {
        $self->_directive_re(qr/INSERT_BLOCK(?:_FROM_MODULE)?/);
    }
}

sub _insert_block {
    my($self, $module, $name, $target) = @_;

    local @INC = ("lib", @INC);
    my $file = module_path(module=>$module) or
        $self->log_fatal(["can't find path for module %s", $module]);

    $self->SUPER::_insert_block($file, $name, $target);
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert a block of text from another module

=for Pod::Coverage .+

=head1 SYNOPSIS

In dist.ini:

 [InsertBlock::FromModule]

In lib/Baz.pm:

 ...

 # BEGIN_BLOCK: some_code

 ...

 # END_BLOCK

In lib/Foo/Base.pm:

 ...

 =head1 ATTRIBUTES

 =for BEGIN_BLOCK: base_attributes

 =head2 attr1

 =head2 attr2

 =for END_BLOCK: base_attributes

 ...

In lib/Foo/Bar.pm:

 ...

 # INSERT_BLOCK_FROM_MODULE: Bar some_code

 ...

 =head1 ATTRIBUTES

 # INSERT_BLOCK_FROM_MODULE: Foo::Base base_attributes

 =head2 attr3

 ...


=head1 DESCRIPTION

This plugin is just like L<Dist::Zilla::Plugin::InsertBlock>, but instead of
filename in the first argument, you specify module name. Module name will then
be converted into path using L<Module::Path::More>. Die when module path is not
found.


=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertBlock>
