# frozen_string_literal: true

require 'inferno_snapshot_tool'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
