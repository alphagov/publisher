require "test_helper"

class FactCheckRequestFormTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user, :govuk_editor, name: "Joe Bloggs")
    @edition = FactoryBot.create(:edition, :draft, :with_previous_published_edition, title: "New title")
    @form = FactoryBot.build(:fact_check_request_form, user: @user, edition: @edition)
  end
  context "standard validations" do
    context "validations without action" do
      should_not validate_presence_of(:email_addresses)
      should_not validate_presence_of(:zendesk_number)
      should_not validate_presence_of(:reason_for_change)
    end

    context "validations on :send" do
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
      should_not validate_presence_of(:email_addresses).on(:update)
      should_not validate_presence_of(:zendesk_number).on(:update)
      should_not validate_presence_of(:reason_for_change).on(:update)
    end

    context "validations on :resend" do
      should_not validate_presence_of(:email_addresses).on(:resend)
      should_not validate_presence_of(:zendesk_number).on(:resend)
      should_not validate_presence_of(:reason_for_change).on(:resend)
    end
  end

  context "custom validations on :send" do
    context "#valid_email_addresses" do
      should "validate a single email address" do
        @form.email_addresses = "james.stewart@test.gov.uk"

        assert @form.valid?(:send)
        assert_empty @form.errors[:email_addresses]
      end

      should "validate an email address with valid but unusual characters" do
        @form.email_addresses = "James.O'Stewart42@test.gov.uk"

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
            @form.deadline_3i = date.day
            @form.deadline_2i = date.month
            @form.deadline_1i = date.year

            assert @form.valid?(:send), "Expected #{date} to be invalid"
            assert_empty @form.errors[:deadline]
          end
        end
      end

      should "raise an error when deadline is in the past" do
        freeze_time do
          date = 1.day.ago.to_date
          @form.deadline_3i = date.day
          @form.deadline_2i = date.month
          @form.deadline_1i = date.year

          assert_not @form.valid?(:send)
          assert_not_empty @form.errors[:deadline]
          assert_includes @form.errors[:deadline], "The date must be today or up to 30 days in the future"
        end
      end

      should "raise an error when deadline is too far in the future" do
        freeze_time do
          date = 31.days.from_now.to_date
          @form.deadline_3i = date.day
          @form.deadline_2i = date.month
          @form.deadline_1i = date.year

          assert_not @form.valid?(:send)
          assert_not_empty @form.errors[:deadline]
          assert_includes @form.errors[:deadline], "The date must be today or up to 30 days in the future"
        end
      end
    end

    context "#deadline_present" do
      should "be valid when deadline is entered" do
        freeze_time do
          date = 15.days.from_now.to_date
          @form.deadline_3i = date.day
          @form.deadline_2i = date.month
          @form.deadline_1i = date.year

          assert @form.valid?(:send), "Expected #{date} to be invalid"
          assert_empty @form.errors[:deadline]
        end
      end

      should "raise an error when deadline is missing day" do
        freeze_time do
          date = 1.day.ago.to_date
          @form.deadline_3i = date.day
          @form.deadline_2i = date.month
          @form.deadline_1i = ""

          assert_not @form.valid?(:send)
          assert_not_empty @form.errors[:deadline]
          assert_includes @form.errors[:deadline], "Enter a deadline"
        end
      end

      should "raise an error when deadline is missing month" do
        freeze_time do
          date = 1.day.ago.to_date
          @form.deadline_3i = date.day
          @form.deadline_2i = ""
          @form.deadline_1i = date.year

          assert_not @form.valid?(:send)
          assert_not_empty @form.errors[:deadline]
          assert_includes @form.errors[:deadline], "Enter a deadline"
        end
      end

      should "raise an error when deadline is missing year" do
        freeze_time do
          date = 1.day.ago.to_date
          @form.deadline_3i = ""
          @form.deadline_2i = date.month
          @form.deadline_1i = date.year

          assert_not @form.valid?(:send)
          assert_not_empty @form.errors[:deadline]
          assert_includes @form.errors[:deadline], "Enter a deadline"
        end
      end
    end
  end

  context ".deadline=" do
    should "accept input which is a Date" do
      date = Time.zone.tomorrow
      @form.deadline_3i = date.day
      @form.deadline_2i = date.month
      @form.deadline_1i = date.year

      assert_equal Time.zone.tomorrow, @form.deadline
    end

    should "cast an invalid data type to nil" do
      [%w[invalid], "invalid", 123].each do |invalid|
        @form.deadline_3i = invalid
        @form.deadline_2i = invalid
        @form.deadline_1i = invalid

        assert_nil @form.deadline, "#{invalid} should result in nil"
      end
    end

    should "reconstruct the deadline date from multiparameter attributes" do
      Timecop.freeze(Time.zone.now) do
        expected_date = Time.zone.today

        @form.deadline_1i = expected_date.year.to_s
        @form.deadline_2i = expected_date.month.to_s
        @form.deadline_3i = expected_date.day.to_s

        assert_equal expected_date, @form.deadline
      end
    end

    should "return nil if date components are invalid or missing" do
      @form.deadline_1i = "2026"
      @form.deadline_2i = "13"
      @form.deadline_3i = "40"

      assert_nil @form.deadline
    end
  end

  context ".post_new_request_payload" do
    should "build and format the payload" do
      target_date = Time.zone.today + 5.days

      @form.deadline_1i = target_date.year.to_s
      @form.deadline_2i = target_date.month.to_s
      @form.deadline_3i = target_date.day.to_s

      expected_payload = { source_app: "publisher",
                           source_id: @edition.id,
                           source_title: "New title",
                           source_url: "#{Plek.find('publisher')}/editions/#{@edition.id}",
                           requester_name: "Joe Bloggs",
                           requester_email: "joe1@bloggs.com",
                           current_content: { content: { heading: "Body", body: "<h2 class=\"edition-title\">New title</h2>\n<p>Some updated body</p>" } },
                           previous_content: { content: { heading: "Body", body: "<h2 class=\"edition-title\">A key answer to your question 1</h2>\n<p>Some body text</p>" } },
                           deadline: target_date.iso8601,
                           reason_for_change: "because",
                           zendesk_number: "1234567",
                           recipients: ["stub@email.com"],
                           draft_content_id: @edition.content_id,
                           draft_auth_bypass_id: @edition.auth_bypass_id,
                           draft_slug: @edition.slug }

      assert_equal expected_payload, @form.post_new_request_payload
    end

    should "build and format the payload with no previous content" do
      @new_draft_edition = FactoryBot.build(:edition, :draft, title: "New title")
      target_date = Time.zone.today + 5.days

      @form.deadline_1i = target_date.year.to_s
      @form.deadline_2i = target_date.month.to_s
      @form.deadline_3i = target_date.day.to_s
      @form.edition = @new_draft_edition
      expected_payload = { source_app: "publisher",
                           source_id: @new_draft_edition.id,
                           source_url: "#{Plek.find('publisher')}/editions/#{@new_draft_edition.id}",
                           source_title: "New title",
                           requester_name: "Joe Bloggs",
                           requester_email: "joe1@bloggs.com",
                           current_content: { content: { heading: "Body", body: "<h2 class=\"edition-title\">New title</h2>\n<p>Some body text</p>" } },
                           previous_content: nil,
                           deadline: target_date.iso8601,
                           reason_for_change: "because",
                           zendesk_number: "1234567",
                           recipients: ["stub@email.com"],
                           draft_content_id: @new_draft_edition.content_id,
                           draft_auth_bypass_id: @new_draft_edition.auth_bypass_id,
                           draft_slug: @new_draft_edition.slug }

      assert_equal expected_payload, @form.post_new_request_payload
    end
  end

  context ".resend_emails_payload" do
    should "build and format the payload" do
      expected_payload = { source_app: "publisher",
                           source_id: @edition.id }

      assert_equal expected_payload, @form.resend_emails_payload
    end
  end

  context ".update_content_payload" do
    should "build and format the payload" do
      expected_payload = { source_app: "publisher",
                           source_id: @edition.id,
                           source_title: "New title",
                           current_content: { content: { heading: "Body", body: "<h2 class=\"edition-title\">New title</h2>\n<p>Some updated body</p>" } },
                           draft_auth_bypass_id: @edition.auth_bypass_id,
                           draft_slug: @edition.slug }

      assert_equal expected_payload, @form.update_content_payload
    end
  end
end
