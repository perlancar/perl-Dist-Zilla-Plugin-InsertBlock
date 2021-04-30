package Dist::Zilla::Plugin::InsertBlock;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles', ':TestFiles'],
    },
);

use namespace::autoclean;

has _directive_re => (is=>'rw', default=>sub{qr/INSERT_BLOCK/});

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content_as_bytes = $file->encoded_content;
    my $directive = $self->_directive_re;
    if ($content_as_bytes =~ s{^#\s*$directive:\s*(.*?)\s+(\w+)(?:\s+(\w+))?\s*$}
                              {$self->_insert_block($1, $2, $3, $file->name)}egm) {
        $file->encoded_content($content_as_bytes);
    }
}

sub _insert_block {
    my($self, $file, $name, $opts, $target) = @_;

    open my($fh), "<", $file or do {
        $self->log_fatal(["can't open %s: %s", $file, $!]);
    };
    my $content = do { local $/; scalar <$fh> };

    my $block;
    if ($content =~ /^=for [ \t]+ BEGIN_BLOCK: [ \t]+ \Q$name\E[ \t]* \R
                     (.*?)
                     ^=for [ \t]+ END_BLOCK: [ \t]+ \Q$name\E/msx) {
        $self->log(["inserting block from '%s' named %s into '%s' (=for syntax)", $file, $name, $target]);
        $block = $1;
    } elsif ($content =~ /^=over [ \t]+ 11 [ \t]* \R\R
                          ^=back [ \t]+ BEGIN_BLOCK: [ \t]+ \Q$name\E[ \t]* \R
                          (.*?)
                          ^=over [ \t]+ 11 [ \t]* \R\R
                          ^=back [ \t]+ END_BLOCK:   [ \t]+ \Q$name\E/msx) {
        $self->log(["inserting block from '%s' named %s into '%s' (=over 11 syntax)", $file, $name, $target]);
        $block = $1;
    } elsif ($content =~ /^\# [ \t]* BEGIN_BLOCK: [ \t]+ \Q$name\E[ \t]* \R
                     (.*?)
                     ^\# [ \t]* END_BLOCK: [ \t]+ \Q$name\E/msx) {
        $self->log(["inserting block from '%s' named %s into '%s' (# syntax)", $file, $name, $target]);
        $block = $1;
    } else {
        $self->log_fatal(["can't find block named %s in file '%s'", $name, $file]);
    }

    $opts //= "";
    if ($opts eq 'pod_verbatim') {
        $block =~ s/^/ /mg;
    }

    return $block;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert a block of text from another file

=for Pod::Coverage .+

=head1 SYNOPSIS

In dist.ini:

 [InsertBlock]

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

 =head1 METHODS

 =over 11

 =back BEGIN_BLOCK: base_methods

 =head2 meth1

 =head2 meth2

 =over 11

 =back END_BLOCK: base_methods

In lib/Foo/Bar.pm:

 ...

 # INSERT_BLOCK: lib/Baz.pm some_code

 ...

 =head1 ATTRIBUTES

 # INSERT_BLOCK: lib/Foo/Base.pm base_attributes

 =head2 attr3

 ...

 =head1 METHODS

 =INSERT_BLOCK: lib/Foo/Base.pm base_methods

 =head2 meth3

 ...


=head1 DESCRIPTION

This plugin finds C<< # INSERT_BLOCK: <file> <name> >> directives in your
POD/code. For each directive, it searches block of text named I<name> in file
I<file>, and inserts the block of text to replace the directive.

Block is marked/defined using either this syntax:

 # BEGIN_BLOCK: Name
 ...
 # END_BLOCK: Name

or this (for block inside POD):

 =for BEGIN_BLOCK: Name

 ...

 =for END_BLOCK: Name

or this syntax (for block inside POD, in case tools like L<Pod::Weaver> removes
C<=for> directives):

 =over 11

 =back BEGIN_BLOCK: Name

 ...

 =over 11

 =back END_BLOCK: Name

Block name is case-sensitive.

This plugin can be useful to avoid repetition/manual copy-paste, e.g. you want
to list POD attributes, methods, etc from a base class into a subclass.

=head2 Options

The C<# INSERT_BLOCK> directive accepts an optional third argument for options.
Known options:

=over

=item * pod_verbatim

This option pads each line of the block content with whitespace. Suitable for
when you are inserting a block into a POD and you want to make the content of
the block as POD verbatim.

=back


=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertBlock::FromModule>

L<Dist::Zilla::Plugin::InsertCodeResult>

L<Dist::Zilla::Plugin::InsertCodeOutput>

L<Dist::Zilla::Plugin::InsertCommandOutput>

L<Dist::Zilla::Plugin::InsertExample> - which basically insert whole files
instead of just a block of text from a file
