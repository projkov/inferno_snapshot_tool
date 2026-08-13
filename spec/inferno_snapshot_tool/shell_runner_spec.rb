# frozen_string_literal: true

RSpec.describe InfernoSnapshotTool::ShellRunner do
  def stub_capture3(stdout:, stderr:, exitstatus:)
    status = instance_double(Process::Status, exitstatus: exitstatus)
    allow(Open3).to receive(:capture3).and_return([stdout, stderr, status])
  end

  it 'parses stdout as JSON when the exit code is allowed' do
    stub_capture3(stdout: '{"id":"abc"}', stderr: '', exitstatus: 0)

    body, exit_code = described_class.run_json('create', 'suite_id')

    expect(body).to eq({ 'id' => 'abc' })
    expect(exit_code).to eq(0)
  end

  it 'allows an alternate exit code when explicitly listed' do
    stub_capture3(stdout: '{"matched":false}', stderr: '', exitstatus: 3)

    body, exit_code = described_class.run_json('compare', 'session_id', allow_exit_codes: [0, 3])

    expect(body).to eq({ 'matched' => false })
    expect(exit_code).to eq(3)
  end

  it 'raises CommandFailed for an unexpected exit code' do
    stub_capture3(stdout: '', stderr: 'boom', exitstatus: 1)

    expect { described_class.run_json('status', 'session_id') }
      .to raise_error(InfernoSnapshotTool::CommandFailed, /boom/)
  end
end
