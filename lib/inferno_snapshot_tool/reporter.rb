# frozen_string_literal: true

module InfernoSnapshotTool
  module Reporter
    def self.print(entry, result)
      if result.matched?
        puts "✅ #{entry.key}: results match the saved snapshot"
        return
      end

      puts "❌ #{entry.key}: #{result.mismatches.size} test(s) differ from the snapshot"
      result.mismatches.each do |c|
        puts "  [#{c['type']}] #{c['id']}"
        puts "    expected: #{c['expected_result'].inspect}"
        puts "    actual:   #{c['actual_result'].inspect}"
      end
    end
  end
end
