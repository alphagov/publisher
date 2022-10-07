require "test_helper"

class KnowledgeApiTest < ActiveSupport::TestCase
  should "tell the publishing API" do
    Services.publishing_api.expects(:put_content)
    Services.publishing_api.expects(:publish)

    KnowledgeApi.new.publish
  end

  should "send valid content" do
    assert_valid_against_publisher_schema(KnowledgeApi.new.payload, "knowledge_alpha")
  end
end
