package MarpaX::Parser::MarpaBase;
use strict;
use warnings;

use Marpa::XS;
use MarpaX::Simple::Lexer;

my %tokens = (
       Name                           => qr/(?^:(\w+))/,
       DeclareOp                      => qr/(?^:::=)/,
       Plus                           => '+',
       Star                           => '*',
       CB                             => qr/(?^:{{)/,
       CE                             => qr/(?^:}})/,
       Code                           => qr/(?^:(?<!{{)\s*(.+)\s*(?=}}))/,
       SLASH                          => '/',
       EQ                             => '=',
       RX                             => qr/(?^:(?<!\/)(.+)(?=(?<!\/)))/,
       Char                           => qr/(?^:\$(.))/,
       WhiteSpace                     => qr/[ \t\r\n]+/,
);
sub MarpaX::Parser::MarpaBase::Actions::Lhs_0 {
	shift; return [ lhs => $_[1] ]
}

sub MarpaX::Parser::MarpaBase::Actions::Decl_0 {
	push @{$_[0]->{rules}}, $_[1] 
}

sub MarpaX::Parser::MarpaBase::Actions::Decl_1 {
	push @{$_[0]->{tokens}}, $_[1] 
}

sub MarpaX::Parser::MarpaBase::Actions::Names_0 {
	shift; return [ @_ ];                    
}

sub MarpaX::Parser::MarpaBase::Actions::Rhs_0 {
	shift; return [ rhs => $_[0] ]           
}

sub MarpaX::Parser::MarpaBase::Actions::Rhs_1 {
	shift; return [ rhs => $_[0], min => 0 ] 
}

sub MarpaX::Parser::MarpaBase::Actions::Rhs_2 {
	shift; return [ rhs => $_[0], min => 1 ] 
}

sub MarpaX::Parser::MarpaBase::Actions::Parser_0 {
	return $_[0]; 
}

sub MarpaX::Parser::MarpaBase::Actions::TokenRule_0 {
	shift; return { @{$_[0]}, regex => qr/$_[3]/ } 
}

sub MarpaX::Parser::MarpaBase::Actions::TokenRule_1 {
	shift; return { @{$_[0]}, 'char' => $_[2] } 
}

sub MarpaX::Parser::MarpaBase::Actions::Rule_0 {
	shift; return { @{$_[0]}, @{$_[4]} };
}

sub MarpaX::Parser::MarpaBase::Actions::Rule_1 {
	shift; return { @{$_[0]}, @{$_[2]}, code => $_[4] }     
}

sub create_grammar {
    my $grammar = Marpa::XS::Grammar->new(
        {   start   => 'Parser',
            actions => 'MarpaX::Parser::MarpaBase::Actions',

          'rules' => [
                       {
                         'min' => 1,
                         'rhs' => [
                                    'Decl'
                                  ],
                         'lhs' => 'Parser',
                         'action' => 'Parser_0'
                       },
                       {
                         'rhs' => [
                                    'Rule'
                                  ],
                         'lhs' => 'Decl',
                         'action' => 'Decl_0'
                       },
                       {
                         'rhs' => [
                                    'TokenRule'
                                  ],
                         'lhs' => 'Decl',
                         'action' => 'Decl_1'
                       },
                       {
                         'rhs' => [
                                    'Lhs',
                                    'EQ',
                                    'SLASH',
                                    'RX',
                                    'SLASH'
                                  ],
                         'lhs' => 'TokenRule',
                         'action' => 'TokenRule_0'
                       },
                       {
                         'rhs' => [
                                    'Lhs',
                                    'EQ',
                                    'Char'
                                  ],
                         'lhs' => 'TokenRule',
                         'action' => 'TokenRule_1'
                       },
                       {
                         'rhs' => [
                                    'Lhs',
                                    'WS',
                                    'DeclareOp',
                                    'WS',
                                    'Rhs'
                                  ],
                         'lhs' => 'Rule',
                         'action' => 'Rule_0'
                       },
                       {
                         'rhs' => [
                                    'Lhs',
                                    'DeclareOp',
                                    'Rhs',
                                    'CB',
                                    'Code',
                                    'CE'
                                  ],
                         'lhs' => 'Rule',
                         'action' => 'Rule_1'
                       },
                       {
                         'rhs' => [
                                    'WS',
                                    'Name'
                                  ],
                         'lhs' => 'Lhs',
                         'action' => 'Lhs_0'
                       },
                       {
                         'rhs' => [
                                    'Names'
                                  ],
                         'lhs' => 'Rhs',
                         'action' => 'Rhs_0'
                       },
                       {
                         'rhs' => [
                                    'Names',
                                    'Star'
                                  ],
                         'lhs' => 'Rhs',
                         'action' => 'Rhs_1'
                       },
                       {
                         'rhs' => [
                                    'Names',
                                    'Plus'
                                  ],
                         'lhs' => 'Rhs',
                         'action' => 'Rhs_2'
                       },
                       {
                         'min' => 1,
                         'rhs' => [
                                    'Name'
                                  ],
                         'lhs' => 'Names',
                         'action' => 'Names_0'
                       },
                       {
                           lhs => 'WS',
                           rhs => [ 'WhiteSpace' ],
                           min => 1,
                       },
                       {
                           lhs => 'WS',
                           rhs => [],
                       },
                     ]
        ,            lhs_terminals => 0,
        }
    );
    $grammar->precompute();
    return $grammar;
}
sub new {
    my ($klass) = @_;
    my $self = bless {}, $klass;
    return $self;
}

sub parse {
    my ($self, $fh) = @_;
    my $grammar = create_grammar();
    my $recognizer = Marpa::XS::Recognizer->new({ grammar => $grammar });
    my $simple_lexer = MarpaX::Simple::Lexer->new(
        recognizer     => $recognizer,
        tokens         => \%tokens,
    );
    $simple_lexer->recognize($fh);
    my $parse_tree = ${$recognizer->value};
    return $parse_tree;
}

1;

=head1 NAME

MarpaX::Parser::MarpaBase - Simple base for Marpa parsers

=head1 SYNOPSYS

    use MarpaX::Parser::MarpaBase;
    use Data::Dumper;

    my $parser = MarpaX::Parser::MarpaBase->new();
    open my $fh, '<', $filename or die "Can't load $filename";
    my $ast = $parse->parse($fh);
    print Dumper($ast);

=head1 DESCRIPTION

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Peter Stuifzand <peter@stuifzand.eu>

=head1 COPYRIGHT

Copyright (c) 2012 Peter Stuifzand

=cut
