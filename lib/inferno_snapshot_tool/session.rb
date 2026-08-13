# frozen_string_literal: true

module InfernoSnapshotTool
  class Session
    class RunFailed < StandardError; end

    def self.execute(entry)
      new(entry).tap(&:create!).tap(&:start_run!).tap(&:wait_until_done!)
    end

    attr_reader :entry, :session_id, :run_id

    def initialize(entry)
      @entry = entry
    end

    def create!
      opts = base_opts
      entry.suite_options.each { |k, v| opts += ['--suite_options', "#{k}:#{v}"] }
      body, = ShellRunner.run_json('create', entry.suite_id, *opts)
      @session_id = body.fetch('id')
    end

    def start_run!
      inputs = entry.inputs.flat_map { |k, v| ['--inputs', "#{k}:#{v}"] }
      body, = ShellRunner.run_json('start_run', session_id, 'suite', *inputs, *base_opts)
      @run_id = body.fetch('id')
    end

    def wait_until_done!
      deadline = Time.now + entry.poll_timeout
      loop do
        body, = ShellRunner.run_json('status', session_id, *base_opts)
        case body['status']
        when 'done'
          return body
        when 'waiting'
          raise RunFailed, "Suite #{entry.suite_id} paused on a test needing " \
                            "interactive input (#{body['wait_result_message']}); " \
                            'not usable with headless snapshotting.'
        when 'cancelled', 'error'
          raise RunFailed, "Run #{run_id} ended with status #{body['status']}"
        end
        raise RunFailed, "Timed out waiting for run #{run_id}" if Time.now > deadline

        sleep entry.poll_interval
      end
    end

    def results
      body, = ShellRunner.run_json('results', session_id, *base_opts)
      body
    end

    private

    def base_opts
      ['--inferno_base_url', entry.inferno_base_url]
    end
  end
end
