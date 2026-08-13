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
end
