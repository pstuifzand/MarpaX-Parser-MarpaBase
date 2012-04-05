use lib 'lib';
use 5.14.2;
use IO::String;
use MarpaX::Parser::MarpaBase;
use Data::Dumper;


my $parser = MarpaX::Parser::MarpaBase->new();
my $grammar = <<'GRAMMAR';
Name       = /(\w+)/
DeclareOp  = /::=/
Plus       = $+
Star       = $*
CB         = /{{/
CE         = /}}/
Code       = /(?<!{{)\s*(.+)\s*(?=}})/
SLASH      = $/
EQ         = $=
RX         = /(?<!\/)(.+)(?=(?<!\/))/
Char       = /\$(.)/
WhiteSpace = /[ \r\n\t]+/
QM         = $?

Parser    ::= Decl+                                  {{ return $_[0]; }}
Decl      ::= Rule WS                                {{ push @{$_[0]->{rules}}, $_[1] }}
Decl      ::= TokenRule WS                           {{ push @{$_[0]->{tokens}}, $_[1] }}
TokenRule ::= Lhs WS EQ WS SLASH RX SLASH            {{ shift; return { @{$_[0]}, regex => qr/$_[5]/ } }}
TokenRule ::= Lhs WS EQ WS Char                      {{ shift; return { @{$_[0]}, 'char' => $_[4] } }}
Rule      ::= Lhs WS DeclareOp WS Rhs                {{ shift; return { @{$_[0]}, @{$_[3]} }     }}
Rule      ::= Lhs WS DeclareOp WS Rhs WS CB Code CE  {{ shift; return { @{$_[0]}, @{$_[3]}, code => $_[7] }     }}
Lhs       ::= WS Name                                {{ shift; return [ lhs => $_[1] ]           }}
Rhs       ::= Names                                  {{ shift; return [ rhs => $_[0] ]           }}
Rhs       ::= Name Star                              {{ shift; return [ rhs => [ $_[0] ], min => 0 ] }}
Rhs       ::= Name Plus                              {{ shift; return [ rhs => [ $_[0] ], min => 1 ] }}
Names     ::= WsName+                                {{ shift; return [ @_ ];                    }}
WsName    ::= Ws Name                                {{ shift; return $_[1]; }}
WS        ::= WhiteSpace+
WS        ::= Null
GRAMMAR

### Parse the grammar
my $io = IO::String->new($grammar);
my $tree = $parser->parse($io);

### Generate a text version of the grammar
for my $token (@{$tree->{tokens}}) {
    if (exists $token->{regex}) {
        say sprintf('%-13s = /%s/', $token->{lhs}, $token->{regex});
    }
    elsif (exists $token->{char}) {
        say sprintf('%-13s = $%s', $token->{lhs}, $token->{char});
    }
}
say "";
for my $rule (@{$tree->{rules}}) {
    my $postfix = '';
    if (exists $rule->{min}) {
        if ($rule->{min} == 0) {
            $postfix = '*';
        }
        elsif ($rule->{min} == 1) {
            $postfix = '+';
        }
    }
    print sprintf('%-13s ::= %-40s', $rule->{lhs}, (join ' ', @{$rule->{rhs}}).$postfix);
    if ($rule->{code}) {
        print "        {{ ", $rule->{code}, " }}";
    }
    print "\n";
}

