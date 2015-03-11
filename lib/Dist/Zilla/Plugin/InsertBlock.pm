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
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;
    if ($content =~ s{^#\s*INSERT_BLOCK:\s*(.*)\s+(\w+)\s*$}{$self->_insert_block($1, $2)."\n"}egm) {
        $self->log(["inserting block from file '%s' named %s into '%s'", $1, $2, $file->name]);
        $file->content($content);
    }
}

sub _insert_block {
    my($self, $file, $name) = @_;

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
        return $1;
    } elsif ($content =~ /^\# [ \t]* BEGIN_BLOCK: [ \t]+ \Q$name\E[ \t]*
                     (?:\n[ \t]*)+
                     (.+?)
                     (?:\n[ \t]*)+
                     ^\# [ \t]* END_BLOCK: [ \t]+ \Q$name\E/msx) {
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

In lib/Foo/Base.pm:

 ...

 =head1 ATTRIBUTES

 =for BEGIN_BLOCK: attributes

 =head2 attr1

 =head2 attr2

 =for END_BLOCK: attributes

 ...

In lib/Foo/Bar.pm:

 ...

 =head1 ATTRIBUTES

 # INSERT_BLOCK: lib/Foo/Bar.pm attributes

 =head2 attr3

 ...


=head1 DESCRIPTION

This plugin finds C<<# INSERT_BLOCK: <file> <name> >> directive in your
POD/code, find the block of text named I<name> in I<file>, and inserts the block
of text to replace the directive.

Block of code is enclosed using either this syntax:

 # BEGIN_BLOCK: Name
 ...
 # END_BLOCK: Name

or this syntax:

 # BEGIN_BLOCK: Name
 ...
 # END_BLOCK: Name

Name is case-sensitive.

This plugin can be useful to avoid repetition/manual copy-paste, e.g. you want
to list POD attributes, methods, etc from a base class into a subclass.


=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertCodeResult>

L<Dist::Zilla::Plugin::InsertCodeOutput>

L<Dist::Zilla::Plugin::InsertCommandOutput>

L<Dist::Zilla::Plugin::InsertExample> - which basically insert whole files
instead of just a block of text from a file

