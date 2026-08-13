# frozen_string_literal: true

require 'inferno_snapshot_tool'
require 'rspec/expectations'

RSpec::Matchers.define :match_inferno_snapshot do
  match do |suite_key|
    entry = InfernoSnapshotTool::Config.load.for(suite_key)
    session = InfernoSnapshotTool::Session.execute(entry)
    @result = InfernoSnapshotTool::Comparator.compare(entry, session)
    @result.matched?
  end

  failure_message do |suite_key|
    lines = ["Results for #{suite_key} no longer match spec/inferno_snapshots/#{suite_key}.json:"]
    @result.mismatches.each do |c|
      lines << "  [#{c['type']}] #{c['id']}: expected=#{c['expected_result'].inspect} actual=#{c['actual_result'].inspect}"
    end
    lines.join("\n")
  end
end
