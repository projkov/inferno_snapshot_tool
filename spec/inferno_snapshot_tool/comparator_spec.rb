# frozen_string_literal: true

RSpec.describe InfernoSnapshotTool::Comparator do
  let(:entry) do
    InfernoSnapshotTool::Config::Entry.new('au_ps_v100', {
                                             'suite_id' => 'au_ps_v100',
                                             'normalized_strings' => ['\d+']
                                           })
  end
  let(:session) { instance_double(InfernoSnapshotTool::Session, session_id: 'sess-1') }

  it 'passes -m, -r, and -n options through to inferno session compare' do
    expect(InfernoSnapshotTool::ShellRunner).to receive(:run_json).with(
      'compare', 'sess-1',
      '--inferno_base_url', 'http://localhost:4567',
      '-f', entry.snapshot_path,
      '-m', '-r',
      '-n', '\d+',
      allow_exit_codes: [0, 3]
    ).and_return([{ 'matched' => true, 'results' => [] }, 0])

    result = described_class.compare(entry, session)

    expect(result.matched?).to be(true)
  end

  it "exposes mismatched comparisons when the run doesn't match" do
    comparisons = [
      { 'matched' => true, 'id' => 'test_a' },
      { 'matched' => false, 'id' => 'test_b' }
    ]
    allow(InfernoSnapshotTool::ShellRunner).to receive(:run_json)
      .and_return([{ 'matched' => false, 'results' => comparisons }, 3])

    result = described_class.compare(entry, session)

    expect(result.matched?).to be(false)
    expect(result.mismatches).to eq([{ 'matched' => false, 'id' => 'test_b' }])
  end
end
