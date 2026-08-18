# frozen_string_literal: true

require 'tmpdir'
require 'json'

RSpec.describe InfernoSnapshotTool::SnapshotStore do
  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  let(:entry) do
    InfernoSnapshotTool::Config::Entry.new('au_ps_v100', { 'suite_id' => 'au_ps_v100', 'snapshot_dir' => @dir })
  end

  it 'writes results sorted by test id so the file diffs cleanly' do
    results = [
      { 'test_id' => 'b_test' },
      { 'test_id' => 'a_test' }
    ]

    path = described_class.save!(entry, results)

    expect(JSON.parse(File.read(path)).map { |r| r['test_id'] }).to eq(%w[a_test b_test])
  end

  it 'reports whether a snapshot file already exists' do
    expect(described_class.exist?(entry)).to be(false)

    described_class.save!(entry, [])

    expect(described_class.exist?(entry)).to be(true)
  end

  describe 'stripping ignored keys' do
    let(:result) do
      {
        'id' => 'result-id',
        'test_id' => 'a_test',
        'test_run_id' => 'run-id',
        'test_session_id' => 'session-id',
        'created_at' => '2026-01-01T00:00:00Z',
        'updated_at' => '2026-01-01T00:00:00Z',
        'result' => 'pass',
        'requests' => [
          { 'id' => 'req-id', 'timestamp' => '2026-01-01T00:00:00Z', 'result_id' => 'result-id', 'url' => 'http://x' }
        ]
      }
    end

    it 'strips the default ignored keys from the top level and from nested requests' do
      path = described_class.save!(entry, [result])
      saved = JSON.parse(File.read(path)).first

      expect(saved.keys).to contain_exactly('test_id', 'result', 'requests')
      expect(saved['requests'].first.keys).to contain_exactly('url')
    end

    it 'strips only the configured keys when ignored_keys is overridden' do
      custom_entry = InfernoSnapshotTool::Config::Entry.new('au_ps_v100', {
                                                              'suite_id' => 'au_ps_v100',
                                                              'snapshot_dir' => @dir,
                                                              'ignored_keys' => %w[id]
                                                            })

      path = described_class.save!(custom_entry, [result])
      saved = JSON.parse(File.read(path)).first

      expect(saved).to include('test_run_id' => 'run-id', 'test_session_id' => 'session-id')
      expect(saved['requests'].first).not_to have_key('id')
      expect(saved['requests'].first).to have_key('result_id')
    end

    it 'strips nothing when ignored_keys is explicitly empty' do
      no_strip_entry = InfernoSnapshotTool::Config::Entry.new('au_ps_v100', {
                                                                'suite_id' => 'au_ps_v100',
                                                                'snapshot_dir' => @dir,
                                                                'ignored_keys' => []
                                                              })

      path = described_class.save!(no_strip_entry, [result])
      saved = JSON.parse(File.read(path)).first

      expect(saved.keys).to match_array(result.keys)
    end

    it 'does not raise for a result with no requests key' do
      no_requests_result = { 'id' => 'result-id', 'test_id' => 'a_test', 'result' => 'pass' }

      expect { described_class.save!(entry, [no_requests_result]) }.not_to raise_error
    end
  end
end
