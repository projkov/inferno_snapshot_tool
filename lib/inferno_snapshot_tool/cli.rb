# frozen_string_literal: true

require 'thor'

module InfernoSnapshotTool
  class CLI < Thor
    class_option :config, type: :string, default: 'inferno_snapshot.yml'

    desc 'init SUITE_KEY', 'Run the suite and save its results as the baseline snapshot'
    def init(suite_key)
      entry = Config.load(options[:config]).for(suite_key)
      session = Session.execute(entry)
      path = SnapshotStore.save!(entry, session.results)
      puts "Saved snapshot for #{suite_key} to #{path}"
    end

    # Thor reserves the bare method name `run`, so the `run` subcommand is
    # implemented as `verify` and aliased below.
    desc 'run SUITE_KEY', 'Run the suite and compare it against the saved snapshot'
    def verify(suite_key)
      entry = Config.load(options[:config]).for(suite_key)
      unless SnapshotStore.exist?(entry)
        raise Thor::Error, "No snapshot at #{entry.snapshot_path} — run `inferno_snapshot_tool init #{suite_key}` first"
      end

      session = Session.execute(entry)
      result = Comparator.compare(entry, session)
      Reporter.print(entry, result)
      exit(1) unless result.matched?
    end
    map 'run' => 'verify'
  end
end
