# frozen_string_literal: true

require 'inferno_snapshot_tool/cli'

RSpec.describe InfernoSnapshotTool::CLI do
  let(:entry) { InfernoSnapshotTool::Config::Entry.new('au_ps_v100', { 'suite_id' => 'au_ps_v100' }) }
  let(:fake_session) { instance_double(InfernoSnapshotTool::Session, session_id: 'sess-1') }

  before do
    config = instance_double(InfernoSnapshotTool::Config, for: entry)
    allow(InfernoSnapshotTool::Config).to receive(:load).and_return(config)
    allow(InfernoSnapshotTool::Session).to receive(:new).and_return(fake_session)
  end

  describe 'init' do
    it 'prints a session id and exits 130 when interrupted, instead of raising' do
      allow(fake_session).to receive(:create!) { raise Interrupt }

      expect { described_class.start(%w[init au_ps_v100]) }
        .to output(/Interrupted — session sess-1 may still be running/).to_stderr
        .and raise_error(SystemExit) { |e| expect(e.status).to eq(130) }
    end

    it 'wires session progress messages through to stdout' do
      allow(InfernoSnapshotTool::Session).to receive(:new) do |_entry, on_progress:|
        on_progress.call('Creating session...')
        fake_session
      end
      allow(fake_session).to receive(:create!)
      allow(fake_session).to receive(:start_run!)
      allow(fake_session).to receive(:wait_until_done!)
      allow(fake_session).to receive(:results).and_return([])
      allow(InfernoSnapshotTool::SnapshotStore).to receive(:save!).and_return('spec/inferno_snapshots/au_ps_v100.json')

      expect { described_class.start(%w[init au_ps_v100]) }.to output(/Creating session/).to_stdout
    end
  end

  describe 'run' do
    before do
      allow(InfernoSnapshotTool::SnapshotStore).to receive(:exist?).with(entry).and_return(true)
    end

    it 'prints a session id and exits 130 when interrupted, instead of raising' do
      allow(fake_session).to receive(:create!) { raise Interrupt }

      expect { described_class.start(%w[run au_ps_v100]) }
        .to output(/Interrupted — session sess-1 may still be running/).to_stderr
        .and raise_error(SystemExit) { |e| expect(e.status).to eq(130) }
    end

    it 'prints a plain interrupted message when no session was ever created' do
      no_session = instance_double(InfernoSnapshotTool::Session, session_id: nil)
      allow(InfernoSnapshotTool::Session).to receive(:new).and_return(no_session)
      allow(no_session).to receive(:create!) { raise Interrupt }

      expect { described_class.start(%w[run au_ps_v100]) }
        .to output("\nInterrupted.\n").to_stderr
        .and raise_error(SystemExit) { |e| expect(e.status).to eq(130) }
    end
  end
end
