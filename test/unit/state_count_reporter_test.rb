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

  should "do nothing if there are no states" do
    statsd_mock = mock("statsd")
    StateCountReporter.new(@model_class, [], statsd_mock).report
  end

  should "report a count for each state" do
    statsd_mock = mock("statsd") do
      expects(:gauge).with("state.draft", 12)
      expects(:gauge).with("state.published", 15)
    end

    StateCountReporter.new(@model_class, @states, statsd_mock).report
  end

  should "return nil" do
    statsd_stub = stub("statsd", gauge: nil)
    assert_nil StateCountReporter.new(@model_class, @states, statsd_stub).report
  end
end
