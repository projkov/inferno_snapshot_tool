# frozen_string_literal: true

require 'yaml'

module InfernoSnapshotTool
  class Config
    class UnknownSuiteKey < StandardError; end

    DEFAULT_IGNORED_KEYS = %w[id created_at updated_at test_run_id test_session_id result_id timestamp].freeze

    def self.load(path = 'inferno_snapshot.yml')
      raw = YAML.safe_load_file(path, aliases: true, symbolize_names: false)
      new(raw.fetch('suites'))
    end

    def initialize(suites_hash)
      @suites = suites_hash
    end

    def for(suite_key)
      entry = @suites[suite_key.to_s]
      raise UnknownSuiteKey, "No config for #{suite_key.inspect} in inferno_snapshot.yml" unless entry

      Entry.new(suite_key.to_s, entry)
    end

    Entry = Struct.new(:key, :raw) do
      def suite_id                = raw.fetch('suite_id')
      def suite_options           = raw.fetch('suite_options', {})
      def inputs                  = raw.fetch('inputs', {})
      def inferno_base_url        = raw.fetch('inferno_base_url', 'http://localhost:4567')
      def snapshot_dir            = raw.fetch('snapshot_dir', 'spec/inferno_snapshots')
      def poll_interval           = raw.fetch('poll_interval', 2)
      def poll_timeout            = raw.fetch('poll_timeout', 900)
      def compare_messages        = raw.fetch('compare_messages', true)
      def compare_result_message  = raw.fetch('compare_result_message', true)
      def normalized_strings      = raw.fetch('normalized_strings', [])
      def ignored_keys            = raw.fetch('ignored_keys', DEFAULT_IGNORED_KEYS)
      def snapshot_path           = File.join(snapshot_dir, "#{key}.json")
    end
  end
end
