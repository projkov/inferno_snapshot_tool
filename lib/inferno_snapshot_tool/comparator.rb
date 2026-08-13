# frozen_string_literal: true

module InfernoSnapshotTool
  class Comparator
    Result = Struct.new(:matched, :comparisons) do
      def matched? = matched

      def mismatches
        comparisons.reject { |c| c['matched'] }
      end
    end

    def self.compare(entry, session)
      opts = ['--inferno_base_url', entry.inferno_base_url,
              '-f', entry.snapshot_path]
      opts += ['-m'] if entry.compare_messages
      opts += ['-r'] if entry.compare_result_message
      # Thor `type: :array` options take one flag followed by multiple
      # space-separated values (`-n pattern1 pattern2`) — repeating the flag
      # instead makes each occurrence overwrite the last (same class of bug
      # as --inputs/--suite_options in session.rb).
      opts += ['-n', *entry.normalized_strings] unless entry.normalized_strings.empty?

      body, = ShellRunner.run_json(
        'compare', session.session_id, *opts, allow_exit_codes: [0, 3]
      )
      Result.new(body.fetch('matched'), body.fetch('results'))
    end
  end
end
