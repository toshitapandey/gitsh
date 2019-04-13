require 'gitsh/error'
require 'gitsh/git_repository'
require 'gitsh/line_editor'
require 'gitsh/magic_variables'

module Gitsh
  class Environment
    DEFAULT_GIT_COMMAND = '/usr/bin/env git'.freeze
    DEFAULT_CONFIG_DIRECTORY = '/usr/local/etc/gitsh'.freeze

    attr_reader :input_stream, :output_stream, :error_stream, :config_directory

    def initialize(options={})
      @input_stream = options.fetch(:input_stream, $stdin)
      @output_stream = options.fetch(:output_stream, $stdout)
      @error_stream = options.fetch(:error_stream, $stderr)
      @repo = options.fetch(:repository_factory, GitRepository).new
      @variables = Hash.new
      @magic_variables = options.fetch(:magic_variables) { MagicVariables.new(@repo) }
      @config_directory = options.fetch(
        :config_directory,
        DEFAULT_CONFIG_DIRECTORY,
      )
    end

    def initialize_copy(original)
      super
      @variables = variables.clone
      self
    end

    def git_command(force_default = false)
      if force_default
        DEFAULT_GIT_COMMAND
      else
        fetch('gitsh.gitCommand', true) { DEFAULT_GIT_COMMAND }
      end
    end

    def git_command=(git_command)
      self['gitsh.gitCommand'] = git_command
    end

    def []=(key, value)
      variables[key.to_sym] = value
    end

    def fetch(key, force_default_git_command = false, &block)
      magic_variables.fetch(key.to_sym) do
        variables.fetch(key.to_sym) do
          repo.config(key.to_s, force_default_git_command, &block)
        end
      end
    rescue KeyError
      raise Gitsh::UnsetVariableError, "Variable '#{key}' is not set"
    end

    def available_variables
      (
        magic_variables.available_variables +
        variables.keys +
        repo.available_config_variables
      ).uniq.sort
    end

    def config_variables
      Hash[variables.select { |key, value| key.to_s.include?('.') }]
    end

    def print(*args)
      output_stream.print(*args)
    end

    def puts(*args)
      output_stream.puts(*args)
    end

    def puts_error(*args)
      error_stream.puts(*args)
    end

    def tty?
      input_stream.tty?
    end

    def repo_branches
      repo.branches
    end

    def repo_tags
      repo.tags
    end

    def repo_remotes
      repo.remotes
    end

    def repo_heads
      repo.heads
    end

    def repo_current_head
      repo.current_head
    end

    def repo_status
      repo.status
    end

    def repo_config_color(name, default)
      if color_override = fetch(name) { false }
        repo.color(color_override)
      else
        repo.config_color(name, default)
      end
    end

    def git_commands
      repo.commands
    end

    def git_aliases
      (repo.aliases + local_aliases).sort
    end

    private

    attr_reader :variables, :magic_variables, :repo

    def local_aliases
      variables.keys.
        select { |key| key.to_s.start_with?('alias.') }.
        map { |key| key.to_s.sub('alias.', '') }
    end
  end
end
