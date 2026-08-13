# frozen_string_literal: true

require_relative 'inferno_snapshot_tool/version'
require_relative 'inferno_snapshot_tool/config'
require_relative 'inferno_snapshot_tool/shell_runner'
require_relative 'inferno_snapshot_tool/session'
require_relative 'inferno_snapshot_tool/snapshot_store'
require_relative 'inferno_snapshot_tool/comparator'
require_relative 'inferno_snapshot_tool/reporter'

module InfernoSnapshotTool
  class Error < StandardError; end
end
