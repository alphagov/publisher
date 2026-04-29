require "test_helper"

class FactCheckRequestFormTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user, :govuk_editor, name: "Joe Bloggs")
    @edition = FactoryBot.create(:edition, :draft, :with_previous_published_edition, title: "New title")
    @form = FactoryBot.build(:fact_check_request_form, user: @user, edition: @edition)
  end
  context "standard validations" do
    context "validations without action" do
      should validate_presence_of(:edition)
      should validate_presence_of(:user)

      should_not validate_presence_of(:deadline)
      should_not validate_presence_of(:email_addresses)
      should_not validate_presence_of(:zendesk_number)
      should_not validate_presence_of(:reason_for_change)
    end

    context "validations on :send" do
      should validate_presence_of(:edition).on(:send)
      should validate_presence_of(:user).on(:send)
      should validate_presence_of(:deadline).on(:send).with_message("Enter a deadline")
      should validate_presence_of(:email_addresses).on(:send).with_message("Enter one or more email addresses")

      should validate_numericality_of(:zendesk_number)
               .only_integer
               .is_greater_than(999_999)
               .with_message("Zendesk number must be a number at least 7 digits long")
               .allow_nil
               .on(:send)

      should_not validate_presence_of(:zendesk_number).on(:send)
      should_not validate_presence_of(:reason_for_change).on(:send)
    end

    context "validations on :update" do
      should validate_presence_of(:edition).on(:update)
      should validate_presence_of(:user).on(:update)

      should_not validate_presence_of(:deadline).on(:update)
      should_not validate_presence_of(:email_addresses).on(:update)
      should_not validate_presence_of(:zendesk_number).on(:update)
      should_not validate_presence_of(:reason_for_change).on(:update)
    end

    context "validations on :resend" do
      should validate_presence_of(:edition).on(:resend)
      should validate_presence_of(:user).on(:resend)

      should_not validate_presence_of(:deadline).on(:resend)
      should_not validate_presence_of(:email_addresses).on(:resend)
      should_not validate_presence_of(:zendesk_number).on(:resend)
      should_not validate_presence_of(:reason_for_change).on(:resend)
    end
  end

  context "custom validations on all actions" do
    context "#user_has_editor_permissions" do
      # Scenario of govuk_editor user is covered by other tests

      should "return true for welsh_editor on welsh content" do
        @form.user = FactoryBot.create(:user, :welsh_editor)
        @form.edition = FactoryBot.create(:edition, :welsh)

        assert @form.valid?
        assert_empty @form.errors[:user]
      end

      should "return false for welsh_editor on non-welsh content" do
        @form.user = FactoryBot.create(:user, :welsh_editor)

        assert_not @form.valid?
        assert_not_empty @form.errors[:user]
        assert_includes @form.errors[:user], "You do not have permission to edit this content"
      end

      should "return false for non-editor" do
        @form.user = FactoryBot.create(:user)

        assert_not @form.valid?
        assert_not_empty @form.errors[:user]
        assert_includes @form.errors[:user], "You do not have permission to edit this content"
      end
    end
  end
  context "custom validations on :send" do
    context "#valid_email_addresses" do
      should "validate a single email address" do
        @form.email_addresses = "james.stewart@test.gov.uk"

        assert @form.valid?(:send)
        assert_empty @form.errors[:email_addresses]
      end

      should "split and validate multiple comma-separated email addresses" do
        ["james.stewart@test.gov.uk, stewart.james@test.gov.uk", "james.stewart@test.gov.uk,stewart.james@test.gov.uk"].each do |emails|
          @form.email_addresses = emails

          assert_equal %w[james.stewart@test.gov.uk stewart.james@test.gov.uk], @form.send(:split_email_addresses)
          assert @form.valid?(:send)
          assert_empty @form.errors[:email_addresses]
        end
      end

      should "split and validate multiple semicolon-separated email addresses" do
        ["james.stewart@test.gov.uk; stewart.james@test.gov.uk", "james.stewart@test.gov.uk;stewart.james@test.gov.uk"].each do |emails|
          @form.email_addresses = emails

          assert_equal %w[james.stewart@test.gov.uk stewart.james@test.gov.uk], @form.send(:split_email_addresses)
          assert @form.valid?(:send)
          assert_empty @form.errors[:email_addresses]
        end
      end

      should "raise an error for incorrectly formatted single email address" do
        invalid_emails = ["plainaddress", "#@%^%\#$@\#$@#.com", "@example.com", "Joe Smith <email@example.com>", "I'm a little teapot@short&stout.com"]

        invalid_emails.each do |invalid_email|
          @form.email_addresses = invalid_email

          assert_not @form.valid?(:send), "Expected #{invalid_email} to be invalid"
          assert_not_empty @form.errors[:email_addresses]
          assert_includes @form.errors[:email_addresses], "Email addresses are invalid"
        end
      end

      should "raise an error if any email in a list is incorrectly formatted" do
        @form.email_addresses = "good@example.com, bad-email, also_good@example.com"

        assert_not @form.valid?(:send)
        assert_not_empty @form.errors[:email_addresses]
        assert_includes @form.errors[:email_addresses], "Email addresses are invalid"
      end
    end

    context "#deadline_in_range" do
      should "be valid when deadline is at extremes of the accepted range" do
        freeze_time do
          [Time.zone.today, 15.days.from_now.to_date, 30.days.from_now.to_date].each do |date|
            @form.deadline = date

            assert @form.valid?(:send), "Expected #{date} to be invalid"
            assert_empty @form.errors[:deadline]
          end
        end
      end

      should "raise an error when deadline is in the past" do
        freeze_time do
          @form.deadline = 1.day.ago.to_date

          assert_not @form.valid?(:send)
          assert_not_empty @form.errors[:deadline]
          assert_includes @form.errors[:deadline], "The date must be today or up to 30 days in the future"
        end
      end

      should "raise an error when deadline is too far in the future" do
        freeze_time do
          @form.deadline = 31.days.from_now.to_date

          assert_not @form.valid?(:send)
          assert_not_empty @form.errors[:deadline]
          assert_includes @form.errors[:deadline], "The date must be today or up to 30 days in the future"
        end
      end
    end
  end

  context ".deadline=" do
    should "accept input which is a Date" do
      @form.deadline = Time.zone.tomorrow

      assert_equal Time.zone.tomorrow, @form.deadline
    end

    should "cast an invalid data type to nil" do
      [%w[invalid], "invalid", 123].each do |invalid|
        @form.deadline = invalid

        assert_nil @form.deadline, "#{invalid} should result in nil"
      end
    end

    should "process a correctly formatted deadline hash, and preserve the raw hash" do
      Timecop.freeze(Time.zone.now) do
        date = Time.zone.today
        input_hash = { "3i" => date.day, "2i" => date.month, "1i" => date.year }
        @form.deadline = input_hash

        assert_equal Time.zone.today, @form.deadline
        assert_equal input_hash, @form.deadline_autofill
      end
    end

    should "recover gracefully from invalid hashes and return nil" do
      [{}, { "1i" => 1, "2i" => 2 }, { "1i" => [], "2i" => false, "3i" => nil }].each do |invalid_hash|
        @form.deadline = invalid_hash

        assert_nil @form.deadline
        assert_equal invalid_hash, @form.deadline_autofill
      end
    end

    should "reject a correctly formatted deadline hash with invalid ints, and preserve the raw hash" do
      input_hash = { "1i" => 999, "2i" => 999, "3i" => 999 }
      @form.deadline = input_hash

      assert_nil @form.deadline
      assert_equal input_hash, @form.deadline_autofill
    end
  end

  context ".request_fact_check" do
    should "build payload and call the fact check manager api adapter" do
      expected_payload = { source_app: "publisher",
                           source_id: @edition.id,
                           source_title: "New title",
                           source_url: "#{Plek.find('publisher')}/editions/#{@edition.id}",
                           requester_name: "Joe Bloggs",
                           requester_email: "joe1@bloggs.com",
                           current_content: { content: { heading: "Body", body: "<p>Some updated body</p>" } },
                           previous_content: { content: { heading: "Body", body: "<p>Some body text</p>" } },
                           deadline: (Time.zone.today + 5.days).iso8601,
                           reason_for_change: "because",
                           zendesk_number: "1234567",
                           recipients: ["stub@email.com"],
                           draft_content_id: @edition.content_id,
                           draft_auth_bypass_id: @edition.auth_bypass_id,
                           draft_slug: @edition.slug }

      Services.fact_check_manager_api.expects(:post_fact_check).with(**expected_payload).returns("stub response")

      @form.request_fact_check
    end

    should "build the payload and call the fact check manager api adapter with no previous content" do
      @new_draft_edition = FactoryBot.build(:edition, :draft, title: "New title")
      @form.edition = @new_draft_edition
      expected_payload = { source_app: "publisher",
                           source_id: @new_draft_edition.id,
                           source_title: "New title",
                           source_url: "#{Plek.find('publisher')}/editions/#{@new_draft_edition.id}",
                           requester_name: "Joe Bloggs",
                           requester_email: "joe1@bloggs.com",
                           current_content: { content: { heading: "Body", body: "<p>Some body text</p>" } },
                           previous_content: nil,
                           deadline: (Time.zone.today + 5.days).iso8601,
                           reason_for_change: "because",
                           zendesk_number: "1234567",
                           recipients: ["stub@email.com"],
                           draft_content_id: @new_draft_edition.content_id,
                           draft_auth_bypass_id: @new_draft_edition.auth_bypass_id,
                           draft_slug: @new_draft_edition.slug }

      Services.fact_check_manager_api.expects(:post_fact_check).with(**expected_payload).returns("stub response")

      @form.request_fact_check
    end
  end

  context ".resend_fact_check_emails" do
    should "call the fact check manager api adapter" do
      Services.fact_check_manager_api.expects(:post_resend_emails)
              .with(source_app: "publisher", source_id: @edition.id)
              .returns("stub response")

      @form.resend_fact_check_emails
    end
  end

  context ".update_fact_check_content" do
    should "build the payload and call the fact check manager api adapter" do
      Services.fact_check_manager_api.expects(:patch_update_content)
              .with(source_app: "publisher",
                    source_id: @edition.id,
                    source_title: "New title",
                    current_content: { content: { heading: "Body", body: "<p>Some updated body</p>" } },
                    draft_auth_bypass_id: @edition.auth_bypass_id,
                    draft_slug: @edition.slug)
              .returns("stub response")

      @form.update_fact_check_content
    end
  end
end
