# frozen_string_literal: true

require 'tmpdir'

RSpec.describe InfernoSnapshotTool::Config do
  let(:yaml) do
    <<~YAML
      suites:
        au_ps_v100:
          suite_id: au_ps_v100
          inputs:
            url: https://example.org/fhir
          normalized_strings:
            - '\\d+'
    YAML
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @path = File.join(dir, 'inferno_snapshot.yml')
      File.write(@path, yaml)
      example.run
    end
  end

  it 'loads a suite entry by key' do
    entry = described_class.load(@path).for('au_ps_v100')

    expect(entry.suite_id).to eq('au_ps_v100')
    expect(entry.inputs).to eq({ 'url' => 'https://example.org/fhir' })
    expect(entry.normalized_strings).to eq(['\\d+'])
  end

  it 'applies documented defaults for optional fields' do
    entry = described_class.load(@path).for('au_ps_v100')

    expect(entry.inferno_base_url).to eq('http://localhost:4567')
    expect(entry.snapshot_dir).to eq('spec/inferno_snapshots')
    expect(entry.poll_interval).to eq(2)
    expect(entry.poll_timeout).to eq(900)
    expect(entry.compare_messages).to be(true)
    expect(entry.compare_result_message).to be(true)
    expect(entry.snapshot_path).to eq('spec/inferno_snapshots/au_ps_v100.json')
  end

  it 'raises for an unknown suite key' do
    expect { described_class.load(@path).for('nope') }.to raise_error(InfernoSnapshotTool::Config::UnknownSuiteKey)
  end

  describe 'ignored_keys' do
    it 'defaults to the standard set of volatile bookkeeping fields' do
      entry = described_class.load(@path).for('au_ps_v100')

      expect(entry.ignored_keys).to eq(InfernoSnapshotTool::Config::DEFAULT_IGNORED_KEYS)
      expect(entry.ignored_keys).to eq(%w[id created_at updated_at test_run_id test_session_id result_id timestamp])
    end

    it 'is a full override, not a merge, when configured' do
      entry = InfernoSnapshotTool::Config::Entry.new('au_ps_v100', {
                                                       'suite_id' => 'au_ps_v100',
                                                       'ignored_keys' => %w[id]
                                                     })

      expect(entry.ignored_keys).to eq(%w[id])
    end
  end
end
