require 'gitsh/shell_command_runner'

module Gitsh
  module Commands
    class ShellCommand
      SHELLWORDS_WHITELIST = 'A-Za-z0-9_\-.,:\/@\n'.freeze
      GLOB_WHITELIST = '\*\[\]!\?\\\\'.freeze
      SHELL_CHARACTER_FILTER = /([^#{SHELLWORDS_WHITELIST}#{GLOB_WHITELIST}])/

      def initialize(command, args, options = {})
        @command = command
        @args = args
      end

      def execute(env)
        ShellCommandRunner.run(command_with_arguments(env), env)
      end

      private

      attr_reader :command, :args

      def command_with_arguments(env)
        [
          '/bin/sh',
          '-c',
          [command, arg_values(env)].flatten.join(' '),
        ]
      end

      def arg_values(env)
        args.values(env).map do |arg|
          arg.gsub(SHELL_CHARACTER_FILTER, '\\\\\\1')
        end
      end
    end
  end
end
