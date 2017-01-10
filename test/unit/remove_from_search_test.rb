require "test_helper"

class RemoveFromSearchTest < ActiveSupport::TestCase
  def test_it_asks_rummager_to_remove_an_artefact_from_search
    Services.rummager.expects(:delete_content!).with("/some-content")

    RemoveFromSearch.call("some-content")
  end

  def test_it_handles_errors
    Services.rummager.expects(:delete_content!)
      .with("/some-content")
      .twice
      .raises(ArgumentError)
    Airbrake.expects(:notify_or_ignore).with(
      instance_of(ArgumentError),
      parameters: { failed_base_path: "/some-content" }
    ).once

    RemoveFromSearch.call("some-content")
  end
end
