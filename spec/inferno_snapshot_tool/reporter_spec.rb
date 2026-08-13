# frozen_string_literal: true

RSpec.describe InfernoSnapshotTool::Reporter do
  let(:entry) { InfernoSnapshotTool::Config::Entry.new('au_ps_v100', { 'suite_id' => 'au_ps_v100' }) }

  it 'prints a success line when results match' do
    result = InfernoSnapshotTool::Comparator::Result.new(true, [])

    expect { described_class.print(entry, result) }.to output(/✅ au_ps_v100: results match/).to_stdout
  end

  it 'prints each mismatch when results differ' do
    comparisons = [
      { 'matched' => false, 'type' => 'Compared', 'id' => 'test_a',
        'expected_result' => 'pass', 'actual_result' => 'fail' }
    ]
    result = InfernoSnapshotTool::Comparator::Result.new(false, comparisons)

    expect { described_class.print(entry, result) }.to output(
      /❌ au_ps_v100: 1 test\(s\) differ.*\[Compared\] test_a.*expected: "pass".*actual:   "fail"/m
    ).to_stdout
  end
end
