# InfernoSnapshotTool

Snapshot-test any [Inferno](https://github.com/onc-healthit/inferno-framework)
test suite's results. `inferno_snapshot_tool` drives the `inferno session`
CLI (`create` / `start_run` / `status` / `results` / `compare`) to record a
baseline run of a suite and later verify that a suite still produces the
same results.

## Installation

Add to the Test Kit's Gemfile:

```ruby
gem "inferno_snapshot_tool"
```

then `bundle install`.

## Configuration

Configure one entry per suite (or per suite + input combination) you want to
snapshot in `inferno_snapshot.yml` at the Test Kit root:

```yaml
suites:
  au_ps_v100:
    suite_id: au_ps_v100
    inputs:
      url: https://hl7-ips-server.hl7.org/fhir
      patient_id: example-r4
    normalized_strings:
      - '/results/[0-9a-fA-F-]{36}/io/inputs/\w+'
    ignored_keys:
      - id
      - created_at
      - updated_at
      - test_run_id
      - test_session_id
      - result_id
      - timestamp
```

`normalized_strings` affects what `run`'s comparison treats as a match (it's
passed straight through to `inferno session compare -n`). `ignored_keys`
affects only the *saved snapshot file*: those keys are stripped from every
result (and from each entry in its `requests`) before `init` writes the
file, so bookkeeping fields that change on every run — ids, timestamps, run
IDs — don't produce noise in the snapshot's git diff. It defaults to
`id`, `created_at`, `updated_at`, `test_run_id`, `test_session_id`,
`result_id`, `timestamp`, so most suites don't need to set it at all.

## Usage

Run from the Test Kit repo root, with Inferno's background services running
(`bundle exec inferno services start`):

```bash
bundle exec inferno_snapshot_tool init au_ps_v100   # record the baseline
bundle exec inferno_snapshot_tool run au_ps_v100    # verify against it
```

Rake tasks and an RSpec matcher are also available — see
`InfernoSnapshotTool::RakeTask` and `require "inferno_snapshot_tool/rspec"`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You
can also run `bin/console` for an interactive prompt. Run `bundle exec rake`
to run the test suite.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/inferno_snapshot_tool. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/inferno_snapshot_tool/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the InfernoSnapshotTool project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/inferno_snapshot_tool/blob/main/CODE_OF_CONDUCT.md).
