package Dist::Zilla::Plugin::InsertBlock;

# DATE
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
    my $content = $file->content;
    my $directive = $self->_directive_re;
    if ($content =~ s{^#\s*$directive:\s*(.*)\s+(\w+)\s*$}{$self->_insert_block($1, $2, $file->name)."\n"}egm) {
        $file->content($content);
    }
}

sub _insert_block {
    my($self, $file, $name, $target) = @_;

    open my($fh), "<", $file or do {
        $self->log_fatal(["can't open %s: %s", $file, $!]);
    };
    my $content;
    {
        local $/;
        $content = <$fh>;
    }

    if ($content =~ /^=for [ \t]+ BEGIN_BLOCK: [ \t]+ \Q$name\E[ \t]*
                     (?:\n[ \t]*)*
                     (.+?)
                     (?:\n[ \t]*)*
                     ^=for [ \t]+ END_BLOCK: [ \t]+ \Q$name\E/msx) {
        $self->log(["inserting block from '%s' named %s into '%s'", $file, $name, $target]);
        return $1;
    } elsif ($content =~ /^\# [ \t]* BEGIN_BLOCK: [ \t]+ \Q$name\E[ \t]*
                     (?:\n[ \t]*)+
                     (.+?)
                     (?:\n[ \t]*)+
                     ^\# [ \t]* END_BLOCK: [ \t]+ \Q$name\E/msx) {
        $self->log(["inserting block from '%s' named %s into '%s'", $file, $name, $target]);
        return $1;
    } else {
        $self->log_fatal(["can't find block named %s in file '%s'", $name, $file]);
    }
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

In lib/Foo/Bar.pm:

 ...

 # INSERT_BLOCK: lib/Baz.pm some_code

 ...

 =head1 ATTRIBUTES

 # INSERT_BLOCK: lib/Foo/Bar.pm base_attributes

 =head2 attr3

 ...


=head1 DESCRIPTION

This plugin finds C<< # INSERT_BLOCK: <file> <name> >> directive in your
POD/code, find the block of text named I<name> in I<file>, and inserts the block
of text to replace the directive.

Block is marked/defined using either this syntax:

 =for BEGIN_BLOCK: Name

 ...

 =for END_BLOCK: Name

or this syntax:

 # BEGIN_BLOCK: Name
 ...
 # END_BLOCK: Name

Block name is case-sensitive.

This plugin can be useful to avoid repetition/manual copy-paste, e.g. you want
to list POD attributes, methods, etc from a base class into a subclass.


=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertBlock::FromModule>

L<Dist::Zilla::Plugin::InsertCodeResult>

L<Dist::Zilla::Plugin::InsertCodeOutput>

L<Dist::Zilla::Plugin::InsertCommandOutput>

L<Dist::Zilla::Plugin::InsertExample> - which basically insert whole files
instead of just a block of text from a file
