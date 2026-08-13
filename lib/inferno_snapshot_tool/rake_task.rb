# frozen_string_literal: true

require 'rake'
require 'rake/tasklib'
require 'inferno_snapshot_tool/cli'

module InfernoSnapshotTool
  class RakeTask < Rake::TaskLib
    def initialize(namespace: :inferno_snapshot)
      super()
      namespace namespace do
        desc 'Record a snapshot baseline for SUITE_KEY'
        task :init, [:suite_key] do |_t, args|
          CLI.start(['init', args.fetch(:suite_key)])
        end

        desc 'Verify SUITE_KEY against its saved snapshot'
        task :run, [:suite_key] do |_t, args|
          CLI.start(['run', args.fetch(:suite_key)])
        end
      end
    end
  end
end
