# frozen_string_literal: true

require 'fileutils'
require 'json'

module InfernoSnapshotTool
  class SnapshotStore
    def self.save!(entry, results)
      FileUtils.mkdir_p(entry.snapshot_dir)
      cleaned = results.map { |result| strip_ignored_keys(result, entry.ignored_keys) }
      sorted = cleaned.sort_by { |r| r['test_id'] || r['test_group_id'] || r['test_suite_id'] || '' }
      File.write(entry.snapshot_path, JSON.pretty_generate(sorted))
      entry.snapshot_path
    end

    def self.exist?(entry)
      File.exist?(entry.snapshot_path)
    end

    def self.strip_ignored_keys(result, keys)
      cleaned = result.reject { |k, _| keys.include?(k) }
      return cleaned unless cleaned['requests'].is_a?(Array)

      cleaned.merge('requests' => cleaned['requests'].map { |req| req.reject { |k, _| keys.include?(k) } })
    end
  end
end
