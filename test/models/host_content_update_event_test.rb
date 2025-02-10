require "test_helper"

class HostContentUpdateEventTest < ActiveSupport::TestCase
  extend Minitest::Spec::DSL

  let(:artefact) { FactoryBot.create(:artefact) }

  describe ".all_for_artefact" do
    it "returns all HostContentUpdateJobs" do
      user1_uuid = SecureRandom.uuid
      user2_uuid = SecureRandom.uuid

      users = [
        {
          "uid" => user1_uuid,
          "name" => "User 1",
          "email" => "user1@example.com",
        },
        {
          "uid" => user2_uuid,
          "name" => "User 2",
          "email" => "user2@example.com",
        },
      ]

      Services.signon_api.expects(:get_users)
              .with(uuids: [user1_uuid, user2_uuid])
              .returns(users)

      Services.publishing_api.expects(:get_events_for_content_id).with(
        artefact.content_id, { action: "HostContentUpdateJob" }
      ).returns(
        [
          {
            "id" => 1593,
            "action" => "HostContentUpdateJob",
            "created_at" => "2024-01-01T00:00:00.000Z",
            "updated_at" => "2024-01-01T00:00:00.000Z",
            "request_id" => SecureRandom.uuid,
            "content_id" => artefact.content_id,
            "payload" => {
              "title" => "Host content updated by content block update",
              "locale" => "en",
              "content_id" => artefact.content_id,
              "source_block" => {
                "title" => "An exciting piece of content",
                "content_id" => "ef224ae6-7a81-4c59-830b-e9884fe57ec8",
                "updated_by_user_uid" => user1_uuid,
                "document_type" => "content_block_email_address",
              },
            },
          },
          {
            "id" => 1593,
            "action" => "HostContentUpdateJob",
            "user_uid" => SecureRandom.uuid,
            "created_at" => "2023-12-01T00:00:00.000Z",
            "updated_at" => "2023-12-01T00:00:00.000Z",
            "request_id" => SecureRandom.uuid,
            "content_id" => artefact.content_id,
            "payload" => {
              "title" => "Host content updated by content block update",
              "locale" => "en",
              "content_id" => artefact.content_id,
              "source_block" => {
                "title" => "Another exciting piece of content",
                "content_id" => "5c5520ce-6677-4a76-bd6e-4515f46a804e",
                "updated_by_user_uid" => user2_uuid,
                "document_type" => "content_block_something_else",
              },
            },
          },
        ],
        )

      result = HostContentUpdateEvent.all_for_artefact(artefact)

      assert_equal result.count, 2

      assert_equal result.first.author.name, "User 1"
      assert_equal result.first.author.email, "user1@example.com"
      assert_equal result.first.created_at, Time.zone.parse("2024-01-01T00:00:00.000Z")
      assert_equal result.first.content_id, "ef224ae6-7a81-4c59-830b-e9884fe57ec8"
      assert_equal result.first.content_title, "An exciting piece of content"
      assert_equal result.first.document_type, "content_block_email_address"

      assert_equal result.second.author.name, "User 2"
      assert_equal result.second.author.email, "user2@example.com"
      assert_equal result.second.created_at, Time.zone.parse("2023-12-01T00:00:00.000Z")
      assert_equal result.second.content_id, "5c5520ce-6677-4a76-bd6e-4515f46a804e"
      assert_equal result.second.content_title, "Another exciting piece of content"
      assert_equal result.second.document_type, "content_block_something_else"
    end
  end
end
