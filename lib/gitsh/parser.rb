require 'rltk'
require 'gitsh/arguments/brace_expansion'
require 'gitsh/arguments/string_argument'
require 'gitsh/arguments/composite_argument'
require 'gitsh/arguments/variable_argument'
require 'gitsh/arguments/subshell'
require 'gitsh/commands/lazy_command'
require 'gitsh/commands/noop'
require 'gitsh/commands/tree'

module Gitsh
  class Parser < RLTK::Parser
    left :EOL
    left :SEMICOLON
    left :OR
    left :AND

    production(:program) do
      clause('SPACE? .commands SEMICOLON? SPACE?') { |c| c }
      clause('SPACE?') { |_| Commands::Noop.new }
    end

    production(:commands) do
      clause('command') { |c| c }
      clause('LEFT_PAREN .commands RIGHT_PAREN SPACE?') { |c| c }
      clause('.commands EOL .commands') { |c1, c2| Commands::Tree::Multi.new(c1, c2) }
      clause('.commands SEMICOLON .commands') { |c1, c2| Commands::Tree::Multi.new(c1, c2) }
      clause('.commands OR .commands') { |c1, c2| Commands::Tree::Or.new(c1, c2) }
      clause('.commands AND .commands') { |c1, c2| Commands::Tree::And.new(c1, c2) }
    end

    production(:command, 'argument_list') do |args|
      Commands::LazyCommand.new(args)
    end

    production(:argument_list) do
      clause('.argument') { |arg| [arg] }
      clause('.argument_list SPACE .argument') { |list, arg| list + [arg] }
    end

    production(:argument) do
      clause('argument_part') { |part| part }
      clause('argument_part argument') do |part, argument|
        Arguments::CompositeArgument.new([part, argument])
      end
    end

    production(:argument_part) do
      clause(:word) { |word| Arguments::StringArgument.new(word) }
      clause(:VAR) { |var| Arguments::VariableArgument.new(var) }
      clause(:subshell) { |program| Arguments::Subshell.new(program) }
      clause(:brace_expansion) { |brace_expansion| brace_expansion }
    end

    production(:brace_expansion) do
      clause('LEFT_BRACE RIGHT_BRACE') do |_, _|
        Arguments::BraceExpansion.new([Arguments::StringArgument.new('')])
      end
      clause('LEFT_BRACE .brace_expansion_list RIGHT_BRACE') do |options|
        Arguments::BraceExpansion.new(options)
      end
    end

    production(:brace_expansion_list) do
      clause('argument') { |option| [option] }
      clause('.brace_expansion_list COMMA .argument') do |options, option|
        options + [option]
      end
      clause('.brace_expansion_list COMMA') do |options|
        options + [Arguments::StringArgument.new('')]
      end
      clause('COMMA .brace_expansion_list') do |options|
        [Arguments::StringArgument.new('')] + options
      end
    end

    production(:word, 'WORD+') { |words| words.inject(:+) }

    production(:subshell, 'SUBSHELL_START .program SUBSHELL_END') { |p| p }

    finalize
  end
end
