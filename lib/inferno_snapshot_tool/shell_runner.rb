# frozen_string_literal: true

require 'open3'
require 'json'

module InfernoSnapshotTool
  class CommandFailed < StandardError
    attr_reader :stdout, :stderr, :status

    def initialize(cmd, stdout, stderr, status)
      @stdout = stdout
      @stderr = stderr
      @status = status
      super("#{cmd.join(' ')} exited #{status.exitstatus}\n#{stderr}")
    end
  end

  class ShellRunner
    # Open3.capture3 reads stdout/stderr on background threads; interrupting
    # (Ctrl-C) mid-read kills those threads and Ruby's default reporting
    # dumps their backtrace to stderr even though we handle the Interrupt
    # ourselves at the CLI level.
    Thread.report_on_exception = false

    # allow_exit_codes: `inferno session compare` legitimately exits 3 on a
    # mismatch — that's a result for us to report, not a shell error.
    def self.run_json(*args, allow_exit_codes: [0])
      cmd = ['bundle', 'exec', 'inferno', 'session', *args]
      stdout, stderr, status = Open3.capture3(*cmd)
      raise CommandFailed.new(cmd, stdout, stderr, status) unless allow_exit_codes.include?(status.exitstatus)

      [JSON.parse(stdout), status.exitstatus]
    end
  end
end
