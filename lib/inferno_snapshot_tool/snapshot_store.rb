# frozen_string_literal: true

require 'fileutils'
require 'json'

module InfernoSnapshotTool
  class SnapshotStore
    def self.save!(entry, results)
      FileUtils.mkdir_p(entry.snapshot_dir)
      sorted = results.sort_by { |r| r['test_id'] || r['test_group_id'] || r['test_suite_id'] || '' }
      File.write(entry.snapshot_path, JSON.pretty_generate(sorted))
      entry.snapshot_path
    end

    def self.exist?(entry)
      File.exist?(entry.snapshot_path)
    end
  end
end
