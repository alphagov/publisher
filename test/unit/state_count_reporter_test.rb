require 'test_helper'
require 'state_count_reporter'

class StateCountReporterTest < ActiveSupport::TestCase
  setup do
    draft_scope_stub = stub("draft scope", count: 12)
    published_scope_stub = stub("published scope", count: 15)
    @model_class = stub(
      "model class",
      draft: draft_scope_stub,
      published: published_scope_stub,
    )
    @states = [:draft, :published]
  end

  should "report a count for each state" do
    statsd_mock = mock("statsd") do
      stubs(:batch).yields(self)
      expects(:gauge).with("state.draft", 12)
      expects(:gauge).with("state.published", 15)
    end

    StateCountReporter.new(@model_class, @states, statsd_mock).report
  end

  should "return nil" do
    statsd_stub = stub("statsd", gauge: nil, batch: nil)
    assert_nil StateCountReporter.new(@model_class, @states, statsd_stub).report
  end

  should "batch the metrics together" do
    # The actual calls to the batch object get tested above
    batch_stub = stub("statsd batch", gauge: nil)
    statsd_mock = mock("statsd") do
      expects(:batch).yields(batch_stub)
    end

    StateCountReporter.new(@model_class, @states, statsd_mock).report
  end
end
