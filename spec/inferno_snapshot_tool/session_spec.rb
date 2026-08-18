# frozen_string_literal: true

RSpec.describe InfernoSnapshotTool::Session do
  let(:entry) do
    InfernoSnapshotTool::Config::Entry.new('au_ps_v100', {
                                             'suite_id' => 'au_ps_v100',
                                             'inputs' => { 'url' => 'https://example.org/fhir' },
                                             'poll_interval' => 0,
                                             'poll_timeout' => 5
                                           })
  end
  let(:session) { described_class.new(entry) }

  describe '#create!' do
    it 'creates a session and captures its id' do
      expect(InfernoSnapshotTool::ShellRunner).to receive(:run_json)
        .with('create', 'au_ps_v100', '--inferno_base_url', 'http://localhost:4567')
        .and_return([{ 'id' => 'sess-1' }, 0])

      session.create!

      expect(session.session_id).to eq('sess-1')
    end

    it 'passes multiple suite options as one --suite_options flag, not repeated flags' do
      multi_option_entry = InfernoSnapshotTool::Config::Entry.new('au_ps_v100', {
                                                                    'suite_id' => 'au_ps_v100',
                                                                    'suite_options' => { 'a' => '1', 'b' => '2' }
                                                                  })
      multi_option_session = described_class.new(multi_option_entry)

      expect(InfernoSnapshotTool::ShellRunner).to receive(:run_json)
        .with('create', 'au_ps_v100', '--suite_options', 'a:1', 'b:2',
              '--inferno_base_url', 'http://localhost:4567')
        .and_return([{ 'id' => 'sess-1' }, 0])

      multi_option_session.create!
    end
  end

  describe '#start_run!' do
    it 'starts a run against the whole suite with the configured inputs' do
      session.instance_variable_set(:@session_id, 'sess-1')

      expect(InfernoSnapshotTool::ShellRunner).to receive(:run_json)
        .with('start_run', 'sess-1', 'suite', '--inputs', 'url:https://example.org/fhir',
              '--inferno_base_url', 'http://localhost:4567')
        .and_return([{ 'id' => 'run-1' }, 0])

      session.start_run!

      expect(session.run_id).to eq('run-1')
    end

    it 'passes multiple inputs as one --inputs flag, not repeated flags' do
      multi_input_entry = InfernoSnapshotTool::Config::Entry.new('au_ps_v100', {
                                                                   'suite_id' => 'au_ps_v100',
                                                                   'inputs' => { 'url' => 'https://example.org/fhir',
                                                                                 'patient_id' => 'example-r4' }
                                                                 })
      multi_input_session = described_class.new(multi_input_entry)
      multi_input_session.instance_variable_set(:@session_id, 'sess-1')

      expect(InfernoSnapshotTool::ShellRunner).to receive(:run_json)
        .with('start_run', 'sess-1', 'suite', '--inputs',
              'url:https://example.org/fhir', 'patient_id:example-r4',
              '--inferno_base_url', 'http://localhost:4567')
        .and_return([{ 'id' => 'run-1' }, 0])

      multi_input_session.start_run!
    end

    it 'omits the --inputs flag entirely when no inputs are configured' do
      no_input_entry = InfernoSnapshotTool::Config::Entry.new('au_ps_v100', { 'suite_id' => 'au_ps_v100' })
      no_input_session = described_class.new(no_input_entry)
      no_input_session.instance_variable_set(:@session_id, 'sess-1')

      expect(InfernoSnapshotTool::ShellRunner).to receive(:run_json)
        .with('start_run', 'sess-1', 'suite', '--inferno_base_url', 'http://localhost:4567')
        .and_return([{ 'id' => 'run-1' }, 0])

      no_input_session.start_run!
    end
  end

  describe '#wait_until_done!' do
    before { session.instance_variable_set(:@session_id, 'sess-1') }

    it 'returns once status is done' do
      allow(InfernoSnapshotTool::ShellRunner).to receive(:run_json)
        .and_return([{ 'status' => 'done' }, 0])

      expect(session.wait_until_done!).to eq({ 'status' => 'done' })
    end

    it 'raises RunFailed when the run needs interactive input' do
      allow(InfernoSnapshotTool::ShellRunner).to receive(:run_json)
        .and_return([{ 'status' => 'waiting', 'wait_result_message' => 'needs SMART launch' }, 0])

      expect { session.wait_until_done! }.to raise_error(described_class::RunFailed, /needs SMART launch/)
    end

    it 'raises RunFailed when the run errors out' do
      allow(InfernoSnapshotTool::ShellRunner).to receive(:run_json)
        .and_return([{ 'status' => 'error' }, 0])

      expect { session.wait_until_done! }.to raise_error(described_class::RunFailed, /ended with status error/)
    end
  end

  describe '#results' do
    it 'fetches the results array' do
      session.instance_variable_set(:@session_id, 'sess-1')

      expect(InfernoSnapshotTool::ShellRunner).to receive(:run_json)
        .with('results', 'sess-1', '--inferno_base_url', 'http://localhost:4567')
        .and_return([[{ 'test_id' => 'a' }], 0])

      expect(session.results).to eq([{ 'test_id' => 'a' }])
    end
  end

  describe 'progress reporting' do
    it 'invokes on_progress at each lifecycle stage, including a status update while waiting' do
      messages = []
      progress_session = described_class.new(entry, on_progress: ->(msg) { messages << msg })
      allow(InfernoSnapshotTool::ShellRunner).to receive(:run_json).and_return(
        [{ 'id' => 'sess-1' }, 0], [{ 'id' => 'run-1' }, 0], [{ 'status' => 'done' }, 0], [[], 0]
      )

      progress_session.create!
      progress_session.start_run!
      progress_session.wait_until_done!
      progress_session.results

      expect(messages).to include(
        a_string_matching(/Creating session/),
        a_string_matching(/Session created: sess-1/),
        a_string_matching(/Starting run/),
        a_string_matching(/Run started: run-1/),
        a_string_matching(/status: done/),
        a_string_matching(/Fetching results/)
      )
    end

    it 'does not emit any output when no on_progress callback is given' do
      session.instance_variable_set(:@session_id, 'sess-1')
      allow(InfernoSnapshotTool::ShellRunner).to receive(:run_json).and_return([{ 'status' => 'done' }, 0])

      expect { session.wait_until_done! }.not_to output.to_stdout
    end
  end
end
