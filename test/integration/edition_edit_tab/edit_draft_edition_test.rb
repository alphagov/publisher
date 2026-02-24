require "integration_test_helper"

class EditDraftEditionTest < IntegrationTest
  setup do
    @govuk_editor = FactoryBot.create(:user, :govuk_editor, name: "Stub User")
    login_as(@govuk_editor)
    UpdateWorker.stubs(:perform_async)
  end

  context "draft edition of a new publication" do
    context "answer edition" do
      setup do
        @draft_edition = FactoryBot.create(:edition,
                                           :draft,
                                           title: "Edit page title",
                                           overview: "metatags",
                                           in_beta: 1,
                                           body: "The body")
        visit edition_path(@draft_edition)
      end

      should "show 'Metadata' header and an update button" do
        within :css, ".gem-c-heading h2" do
          assert page.has_text?("Edit")
        end
        assert page.has_button?("Save")
      end

      should "show 'Send to 2i' link" do
        assert page.has_link?("Send to 2i")
      end

      should "show Preview link" do
        assert page.has_link?("Preview (opens in new tab)")
      end

      should "show Title input box prefilled" do
        assert page.has_text?("Title")
        assert page.has_field?("edition[title]", with: "Edit page title")
      end

      should "show Meta tag input box prefilled" do
        assert page.has_text?("Meta tag description")
        assert page.has_text?("Some search engines will display this if they cannot find what they need in the main text")
        assert page.has_field?("edition[overview]", with: "metatags")
      end

      should "show Beta content radios prechecked" do
        assert page.has_text?("Is this beta content?")
        assert find(".gem-c-radio input[value='0']")
        assert find(".gem-c-radio input[value='1']").checked?
      end

      should "show Body text field prefilled" do
        assert page.has_text?("Body")
        assert page.has_text?("Refer to the Govspeak guidance (opens in new tab)")
        assert page.has_field?("edition[body]", with: "The body")
      end

      should "not show Change Note field for an unpublished document" do
        assert page.has_no_text?("Add a public change note")
        assert page.has_no_text?("Telling users when published information has changed is important for transparency.")
        assert page.has_no_field?("edition[change_note]")
      end

      should "update and show success message" do
        fill_in "edition[title]", with: "Changed Title"
        fill_in "edition[overview]", with: "Changed Meta tag description"
        choose("Yes")
        fill_in "edition[body]", with: "Changed body"
        click_button("Save")

        assert page.has_field?("edition[title]", with: "Changed Title")
        assert page.has_field?("edition[overview]", with: "Changed Meta tag description")
        assert find(".gem-c-radio input[value='1']").checked?
        assert page.has_field?("edition[body]", with: "Changed body")
        assert page.has_text?("Edition updated successfully.")
      end

      should "not show the 'Resend fact check email' link and text" do
        assert page.has_no_link?("Resend fact check email")
        assert page.has_no_text?("You've requested this edition to be fact checked. We're awaiting a response.")
      end

      should "not show the 'Request amendments' link and text" do
        assert page.has_no_link?("Request amendments")
      end

      should "not show the 'Skip review' link" do
        assert page.has_no_link?("Skip review")
      end

      should "not show the 'No changes needed' link" do
        assert page.has_no_link?("No changes needed")
      end

      context "user does not have editor permissions" do
        setup do
          login_as(FactoryBot.create(:user, name: "Non Editor"))
          visit edition_path(@draft_edition)
        end

        should "not show any editable components" do
          assert page.has_no_css?(".govuk-textarea")
          assert page.has_no_css?(".govuk-input")
          assert page.has_no_css?(".govuk-radios")
        end

        should "not show the send to 2i button" do
          assert page.has_no_link?("Send to 2i")
        end

        should "not show the Save button" do
          assert page.has_no_button?("Save")
        end

        should "show the Preview link" do
          assert page.has_link?("Preview (opens in new tab)")
        end
      end
    end

    context "place edition" do
      setup do
        @draft_place_edition = FactoryBot.create(:place_edition,
                                                 :draft,
                                                 title: "Edit page title",
                                                 overview: "metatags",
                                                 in_beta: 1,
                                                 place_type: "The place type",
                                                 introduction: "some intro",
                                                 more_information: "some more info",
                                                 need_to_know: "some need to know")
        visit edition_path(@draft_place_edition)
      end

      should "show fields for place edition" do
        assert page.has_field?("edition[title]", with: "Edit page title")
        assert page.has_field?("edition[overview]", with: "metatags")

        assert page.has_css?(".govuk-label", text: "Places Manager service identifier")
        assert page.has_css?(".govuk-hint", text: "This is assigned in the Places Manager application")
        assert page.has_field?("edition[place_type]", with: "The place type")

        assert page.has_css?(".govuk-label", text: "Introduction")
        assert page.has_css?(".govuk-hint", text: "Refer to the Govspeak guidance (opens in new tab)")
        assert page.has_field?("edition[introduction]", with: "some intro")

        assert page.has_css?(".govuk-label", text: "Further information (optional)")
        assert page.has_field?("edition[more_information]", with: "some more info")

        assert page.has_css?(".govuk-label", text: "What you need to know (optional)")
        assert page.has_field?("edition[need_to_know]", with: "some need to know")

        assert find(".gem-c-radio input[value='1']").checked?
      end

      should "update place edition and show success message" do
        fill_in "edition[title]", with: "Changed Title"
        fill_in "edition[overview]", with: "Changed Meta tag description"
        fill_in "edition[place_type]", with: "Changed place type"
        fill_in "edition[introduction]", with: "Changed intro"
        fill_in "edition[more_information]", with: "Changed more info"
        fill_in "edition[need_to_know]", with: "Changed need to know"
        choose("Yes")
        click_button("Save")

        assert page.has_field?("edition[title]", with: "Changed Title")
        assert page.has_field?("edition[overview]", with: "Changed Meta tag description")
        assert page.has_field?("edition[place_type]", with: "Changed place type")
        assert page.has_field?("edition[introduction]", with: "Changed intro")
        assert page.has_field?("edition[more_information]", with: "Changed more info")
        assert page.has_field?("edition[need_to_know]", with: "Changed need to know")
        assert find(".gem-c-radio input[value='1']").checked?
        assert page.has_text?("Edition updated successfully.")
      end
    end

    context "local transaction edition" do
      setup do
        local_service = FactoryBot.create(:local_service, lgsl_code: 9012, description: "Whatever", providing_tier: %w[district unitary county])
        scotland_availability = FactoryBot.build(:scotland_availability, authority_type: "devolved_administration_service", alternative_url: "https://www.google.com")
        wales_availability = FactoryBot.build(:wales_availability, authority_type: "unavailable")
        draft_local_transaction_edition = FactoryBot.create(:local_transaction_edition, :draft, title: "Edit page title", in_beta: 1, lgsl_code: local_service.lgsl_code,
                                                                                                panopticon_id: FactoryBot.create(:artefact).id, lgil_code: 23, cta_text: "Find your local council", introduction: "Test introduction", more_information: "some more info",
                                                                                                need_to_know: "some need to know", before_results: "before results", after_results: "after results", scotland_availability:, wales_availability:)
        visit edition_path(draft_local_transaction_edition)
      end

      should "show fields for local transaction edition" do
        assert page.has_field?("edition[title]", with: "Edit page title")

        assert page.has_css?(".govuk-label", text: "LGSL code")
        assert page.has_text?("9012")

        assert page.has_css?(".govuk-label", text: "LGIL code")
        assert page.has_field?("edition[lgil_code]", with: "23")

        assert page.has_css?(".govuk-label", text: "Button text (optional)")
        assert page.has_css?(".govuk-hint", text: "If left blank, the default text ‘Find your local council’ will be used")
        assert page.has_field?("edition[cta_text]", with: "Find your local council")

        assert page.has_css?(".govuk-label", text: "Introduction")
        assert page.has_css?(".govuk-hint", text: "Set the scene for the user. Explain that it’s the responsibility of the local council and that we’ll take you there. Read the Govspeak guidance (opens in new tab)")
        assert page.has_field?("edition[introduction]", with: "Test introduction")

        assert page.has_css?(".govuk-label", text: "Further information (optional)")
        assert page.has_field?("edition[more_information]", with: "some more info")

        assert page.has_css?(".govuk-label", text: "What you need to know (optional)")
        assert page.has_field?("edition[need_to_know]", with: "some need to know")

        assert page.has_css?(".govuk-label", text: "Above results content (optional)")
        assert page.has_field?("edition[before_results]", with: "before results")

        assert page.has_css?(".govuk-label", text: "Below results content (optional)")
        assert page.has_field?("edition[after_results]", with: "after results")

        within all(".govuk-fieldset")[0] do
          assert page.has_css?("legend", text: "Northern Ireland")
          assert find(".gem-c-radio input[value='local_authority_service']").checked?
        end

        within all(".govuk-fieldset")[1] do
          assert page.has_css?("legend", text: "Scotland")
          assert find(".gem-c-radio input[value='devolved_administration_service']").checked?

          assert page.has_css?(".govuk-label", text: "URL of the devolved administration website page")
          assert page.has_field?("edition[scotland_availability_attributes][alternative_url]", with: "https://www.google.com")
        end

        within all(".govuk-fieldset")[2] do
          assert page.has_css?("legend", text: "Wales")
          assert find(".gem-c-radio input[value='unavailable']").checked?
        end

        assert find(".gem-c-radio input[value='1']").checked?
      end

      should "update local transaction edition and show success message" do
        fill_in "edition[title]", with: "Changed Title"
        fill_in "edition[lgil_code]", with: "25"
        fill_in "edition[cta_text]", with: "Changed button text"
        fill_in "edition[introduction]", with: "Changed intro"
        fill_in "edition[more_information]", with: "Changed more info"
        fill_in "edition[need_to_know]", with: "Changed need to know"
        fill_in "edition[before_results]", with: "Changed above results"
        fill_in "edition[after_results]", with: "Changed below results"

        within all(".govuk-fieldset")[0] do
          choose("Service not available")
        end

        within all(".govuk-fieldset")[1] do
          choose("Service available from local council")
        end

        within all(".govuk-fieldset")[2] do
          choose("Service available from devolved administration (or a similar service is available)")
          fill_in "edition[wales_availability_attributes][alternative_url]", with: "https://www.google.com"
        end

        choose("Yes")
        click_button("Save")

        assert page.has_field?("edition[title]", with: "Changed Title")
        assert page.has_field?("edition[lgil_code]", with: "25")
        assert page.has_field?("edition[cta_text]", with: "Changed button text")
        assert page.has_field?("edition[introduction]", with: "Changed intro")
        assert page.has_field?("edition[more_information]", with: "Changed more info")
        assert page.has_field?("edition[need_to_know]", with: "Changed need to know")
        assert page.has_field?("edition[before_results]", with: "Changed above results")
        assert page.has_field?("edition[after_results]", with: "Changed below results")

        within all(".govuk-fieldset")[0] do
          assert page.has_css?("legend", text: "Northern Ireland")
          assert find(".gem-c-radio input[value='unavailable']").checked?
        end

        within all(".govuk-fieldset")[1] do
          assert page.has_css?("legend", text: "Scotland")
          assert find(".gem-c-radio input[value='local_authority_service']").checked?
        end

        within all(".govuk-fieldset")[2] do
          assert page.has_css?("legend", text: "Wales")
          assert find(".gem-c-radio input[value='devolved_administration_service']").checked?

          assert page.has_css?(".govuk-label", text: "URL of the devolved administration website page")
          assert page.has_field?("edition[wales_availability_attributes][alternative_url]", with: "https://www.google.com")
        end

        assert find(".gem-c-radio input[value='1']").checked?
        assert page.has_text?("Edition updated successfully.")
      end

      should "should show an error message when URL of the devolved administration is blank" do
        within all(".govuk-fieldset")[2] do
          choose("Service available from devolved administration (or a similar service is available)")
          fill_in "edition[wales_availability_attributes][alternative_url]", with: ""
        end

        click_button("Save")

        within all(".govuk-fieldset")[2] do
          assert page.has_css?("legend", text: "Wales")
          assert find(".gem-c-radio input[value='devolved_administration_service']").checked?

          assert page.has_text?("Enter the URL of the devolved administration website page")
        end
      end

      should "should show an error message when URL of the devolved administration is invalid" do
        within all(".govuk-fieldset")[2] do
          choose("Service available from devolved administration (or a similar service is available)")
          fill_in "edition[wales_availability_attributes][alternative_url]", with: "some text"
        end

        click_button("Save")

        within all(".govuk-fieldset")[2] do
          assert page.has_css?("legend", text: "Wales")
          assert find(".gem-c-radio input[value='devolved_administration_service']").checked?

          assert page.has_text?("Must be a full URL, starting with https://")
        end
      end

      should "should show an error message when LGIL code is blank" do
        fill_in "edition[lgil_code]", with: ""
        click_button("Save")

        assert page.has_text?("Enter a LGIL code")
      end

      should "should show an error message when LGIL code is invalid" do
        fill_in "edition[lgil_code]", with: "some text"
        click_button("Save")

        assert page.has_text?("LGIL code can only be a whole number between 0 and 999")
      end
    end

    context "guide edition" do
      setup do
        @draft_guide_edition = FactoryBot.create(:guide_edition, :draft, title: "Edit page title", overview: "metatags", in_beta: 1, hide_chapter_navigation: 1)
        visit edition_path(@draft_guide_edition)
      end

      context "when the 'guide_chapter_accordion_interface' feature toggle is off" do
        setup do
          @test_strategy.switch!(:guide_chapter_accordion_interface, false)
        end

        context "user has editor permissions" do
          should "show fields for guide edition" do
            assert page.has_field?("edition[title]", with: "Edit page title")
            assert page.has_field?("edition[overview]", with: "metatags")

            assert page.has_css?(".govuk-heading-m", text: "Chapters")
            assert page.has_css?(".govuk-button", text: "Add a new chapter")

            within all(".govuk-fieldset")[0] do
              assert page.has_css?("legend", text: "Is every chapter part of a step by step?")
              assert page.has_css?(".govuk-hint", text: "The chapter navigation will be hidden if they all are")
              assert find(".gem-c-radio input[value='1']").checked?
            end

            within all(".govuk-fieldset")[1] do
              assert page.has_css?("legend", text: "Is this beta content?")
              assert find(".gem-c-radio input[value='1']").checked?
            end
          end

          should "show guide chapter list for guide edition if present" do
            draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :draft, title: "Edit page title", overview: "metatags", in_beta: 1, hide_chapter_navigation: 1, panopticon_id: FactoryBot.create(:artefact).id, publish_at: Time.zone.now + 1.hour)
            visit edition_path(draft_guide_edition_with_parts)

            assert page.has_field?("edition[title]", with: "Edit page title")
            assert page.has_field?("edition[overview]", with: "metatags")
            assert page.has_css?(".govuk-heading-m", text: "Chapters")
            assert page.has_css?(".govuk-summary-list__row", text: "PART !")
            assert page.has_css?(".govuk-summary-list__row", text: "PART !!")
            assert page.has_css?(".govuk-summary-list__actions", text: "Edit", minimum: 2)
            assert page.has_css?(".govuk-button", text: "Add a new chapter")

            within all(".govuk-fieldset")[0] do
              assert page.has_css?("legend", text: "Is every chapter part of a step by step?")
              assert page.has_css?(".govuk-hint", text: "The chapter navigation will be hidden if they all are")
              assert find(".gem-c-radio input[value='1']").checked?
            end

            within all(".govuk-fieldset")[1] do
              assert page.has_css?("legend", text: "Is this beta content?")
              assert find(".gem-c-radio input[value='1']").checked?
            end
          end

          should "order guide chapter list by part order attribute" do
            draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :draft)
            draft_guide_edition_with_parts.parts.min_by(&:order).update!(order: 5)

            visit edition_path(draft_guide_edition_with_parts)

            within all(".govuk-summary-list__row")[3] do
              assert_text "PART !!"
            end

            within all(".govuk-summary-list__row")[4] do
              assert_text "PART !"
            end
          end

          should "update guide edition and show success message" do
            fill_in "edition[title]", with: "Changed Title"
            fill_in "edition[overview]", with: "Changed Meta tag description"

            within all(".govuk-fieldset")[0] do
              choose("Yes")
            end

            within all(".govuk-fieldset")[1] do
              choose("Yes")
            end

            click_button("Save")

            assert page.has_field?("edition[title]", with: "Changed Title")
            assert page.has_field?("edition[overview]", with: "Changed Meta tag description")

            within all(".govuk-fieldset")[0] do
              assert page.has_css?("legend", text: "Is every chapter part of a step by step?")
              assert page.has_css?(".govuk-hint", text: "The chapter navigation will be hidden if they all are")
              assert find(".gem-c-radio input[value='1']").checked?
            end

            within all(".govuk-fieldset")[1] do
              assert page.has_css?("legend", text: "Is this beta content?")
              assert find(".gem-c-radio input[value='1']").checked?
            end

            assert page.has_text?("Edition updated successfully.")
          end

          should "show Add new chapter page when Add new chapter button is clicked" do
            click_link("Add a new chapter")

            assert page.has_content?("Add new chapter")
            assert page.has_css?(".govuk-label", text: "Title")
            assert page.has_css?(".govuk-label", text: "Slug")
            assert page.has_css?(".govuk-label", text: "Body")
          end

          should "show Edit chapter page when Edit chapter link is clicked" do
            draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :draft, title: "Edit page title", overview: "metatags", in_beta: 1, hide_chapter_navigation: 1, panopticon_id: FactoryBot.create(:artefact).id, publish_at: Time.zone.now + 1.hour)
            visit edition_path(draft_guide_edition_with_parts)

            within all(".govuk-summary-list__row").last do
              click_link("Edit")
            end

            assert page.has_content?("Edit chapter")
            assert page.has_field?("part[title]", with: "PART !!")
            assert page.has_field?("part[slug]", with: "part-two")
            assert page.has_field?("part[body]", with: "This is some more version text.")
          end

          should "not show 'Reorder chapters' button when no parts are present" do
            assert page.has_no_link?("Reorder chapters")
          end

          should "not show 'Reorder chapters' button when 1 part is present" do
            @draft_guide_edition.parts.build(
              title: "PART !",
              body: "This is some version text.",
              slug: "part-one",
              order: 1,
            )
            @draft_guide_edition.save!
            @draft_guide_edition.reload

            assert page.has_no_link?("Reorder chapters")
          end

          should "show an error if the user tries to directly access the reorder chapters page with less than two parts" do
            visit reorder_edition_guide_parts_path(@draft_guide_edition)

            assert current_path == edition_path(@draft_guide_edition)
            assert page.has_content?("You can only reorder chapters when there are at least 2.")
          end

          should "show 'Reorder chapters' button when two parts are present" do
            draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :draft, title: "Edit page title", overview: "metatags", in_beta: 1, hide_chapter_navigation: 1, panopticon_id: FactoryBot.create(:artefact).id, publish_at: Time.zone.now + 1.hour)
            visit edition_path(draft_guide_edition_with_parts)

            assert page.has_link?("Reorder chapters")
          end

          context "Add new chapter" do
            setup do
              click_link("Add a new chapter")
            end

            should "save and redirect to edit guide page when 'save and go to summary' button is clicked" do
              fill_in "Title", with: "Part One"
              fill_in "Slug", with: "part-one"
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_path(@draft_guide_edition)
              assert page.has_content?("New chapter added successfully.")
              assert page.has_css?(".govuk-summary-list__row", text: "Part One")
            end

            should "show validation error when Title is empty" do
              fill_in "Title", with: ""
              fill_in "Slug", with: "part-one"
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_guide_parts_path(@draft_guide_edition)
              assert page.has_field?("part[title]", with: "")
              assert page.has_field?("part[slug]", with: "part-one")
              assert page.has_field?("part[body]", with: "body-text")
              assert page.has_content?("Enter a title")
            end

            should "show validation error when Slug is empty" do
              fill_in "Title", with: "Part one"
              fill_in "Slug", with: ""
              fill_in "Body", with: "body-text"
              click_button("Save and go to summary")

              assert_current_path edition_guide_parts_path(@draft_guide_edition)
              assert page.has_field?("part[title]", with: "Part one")
              assert page.has_field?("part[slug]", with: "")
              assert page.has_field?("part[body]", with: "body-text")
              assert page.has_content?("Enter a slug")
            end

            should "show validation error when Slug is invalid" do
              fill_in "Title", with: "Part one"
              fill_in "Slug", with: "@"
              fill_in "Body", with: "body-text"
              click_button("Save and go to summary")

              assert_current_path edition_guide_parts_path(@draft_guide_edition)
              assert page.has_field?("part[title]", with: "Part one")
              assert page.has_field?("part[slug]", with: "@")
              assert page.has_field?("part[body]", with: "body-text")
              assert page.has_content?("Slug can only consist of lower case characters, numbers and hyphens")
            end

            should "redirect to guide edit page when back to summary link is clicked" do
              click_link("Back to summary")

              assert_current_path edition_path(@draft_guide_edition)
              assert page.has_content?("Edit")
            end

            should "display the guide edit page when the 'Cancel and discard changes' link is clicked" do
              click_link("Cancel and discard changes")

              assert_current_path edition_path(@draft_guide_edition)
              assert page.has_content?("Edit")
            end
          end

          context "Reorder Chapters" do
            setup do
              @draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :draft, title: "Edit page title", overview: "metatags", in_beta: 1, hide_chapter_navigation: 1, panopticon_id: FactoryBot.create(:artefact).id, publish_at: Time.zone.now + 1.hour)
              visit edition_path(@draft_guide_edition_with_parts)
              click_link("Reorder chapters")
            end

            should "reorder chapters and redirect to guide edit page when update order is clicked" do
              within all(".gem-c-reorderable-list__item")[0] do
                fill_in "Position", with: "2"
              end
              within all(".gem-c-reorderable-list__item")[1] do
                fill_in "Position", with: "1"
              end

              click_button "Update order"

              within all(".govuk-summary-list__row")[3] do
                assert page.has_text?("PART !!")
              end
              within all(".govuk-summary-list__row")[4] do
                assert page.has_text?("PART !")
              end
            end

            should "not reorder chapters and redirect to guide edit page when cancel is clicked" do
              within all(".gem-c-reorderable-list__item")[0] do
                fill_in "Position", with: "2"
              end
              within all(".gem-c-reorderable-list__item")[1] do
                fill_in "Position", with: "1"
              end

              click_link "Cancel"

              within all(".govuk-summary-list__row")[3] do
                assert page.has_text?("PART !")
              end
              within all(".govuk-summary-list__row")[4] do
                assert page.has_text?("PART !!")
              end
            end
          end

          context "Edit chapter" do
            setup do
              @draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :draft, title: "Edit page title", overview: "metatags", in_beta: 1, hide_chapter_navigation: 1, panopticon_id: FactoryBot.create(:artefact).id, publish_at: Time.zone.now + 1.hour)
              @part_id = @draft_guide_edition_with_parts.parts.last.id
              visit edition_path(@draft_guide_edition_with_parts)
              within all(".govuk-summary-list__row").last do
                click_link("Edit")
              end
            end

            should "save and redirect to edit guide page when save and summary button is clicked" do
              fill_in "Title", with: "PART !!!"
              fill_in "Slug", with: "part-two"
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_path(@draft_guide_edition_with_parts)
              assert page.has_content?("Chapter updated successfully.")
              assert page.has_css?(".govuk-summary-list__row", text: "PART !!!")
            end

            should "show validation error when Title is empty" do
              fill_in "Title", with: ""
              fill_in "Slug", with: "part-two"
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_guide_part_path(@draft_guide_edition_with_parts, @part_id)
              assert page.has_field?("part[title]", with: "")
              assert page.has_field?("part[slug]", with: "part-two")
              assert page.has_field?("part[body]", with: "body-text")
              assert page.has_content?("Enter a title for Chapter 2")
            end

            should "show validation error when Slug is empty" do
              fill_in "Title", with: "Part two"
              fill_in "Slug", with: ""
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_guide_part_path(@draft_guide_edition_with_parts, @part_id)
              assert page.has_field?("part[title]", with: "Part two")
              assert page.has_field?("part[slug]", with: "")
              assert page.has_field?("part[body]", with: "body-text")
              assert page.has_content?("Enter a slug for Chapter 2")
            end

            should "show validation error when Slug is invalid" do
              fill_in "Title", with: "Part two"
              fill_in "Slug", with: "@"
              fill_in "Body", with: "body-text"

              click_button("Save and go to summary")

              assert_current_path edition_guide_part_path(@draft_guide_edition_with_parts, @part_id)
              assert page.has_field?("part[title]", with: "Part two")
              assert page.has_field?("part[slug]", with: "@")
              assert page.has_field?("part[body]", with: "body-text")
              assert page.has_content?("Slug for Chapter 2 can only consist of lower case characters, numbers and hyphens")
            end

            should "redirect to guide edit page when back to summary link is clicked" do
              click_link("Back to summary")

              assert_current_path edition_path(@draft_guide_edition_with_parts)
              assert page.has_content?("Edit")
            end

            should "display the Delete chapter confirmation page when the 'Delete chapter' link is clicked" do
              click_link("Delete chapter")

              assert_current_path confirm_destroy_edition_guide_part_path(@draft_guide_edition_with_parts, @part_id)
              assert page.has_content?("Are you sure you want to delete this chapter?")
            end
          end
        end

        context "user has no editor permissions" do
          setup do
            login_as(FactoryBot.create(:user, name: "Non Editor"))
            @draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :draft, title: "Edit page title", overview: "metatags", in_beta: 1, hide_chapter_navigation: 1, panopticon_id: FactoryBot.create(:artefact).id, publish_at: Time.zone.now + 1.hour)
            visit edition_path(@draft_guide_edition_with_parts)
          end

          should "not show 'Add new chapter' button" do
            assert_not page.has_css?(".govuk-button", text: "Add a new chapter")
          end

          should "not show 'Reorder chapters' button even with two parts present" do
            assert page.has_no_link?("Reorder chapters")
          end

          should "not allow user to load reorder chapters page" do
            visit reorder_edition_guide_parts_path(@draft_guide_edition_with_parts)

            assert current_path == edition_path(@draft_guide_edition_with_parts)
            assert page.has_content?("You do not have correct editor permissions for this action.")
          end

          should "not show the 'Delete chapter' button'" do
            assert page.has_no_link?("Delete chapter")
          end
        end

        context "Delete chapter confirmation" do
          setup do
            @draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :draft, title: "Edit page title", overview: "metatags", in_beta: 1, hide_chapter_navigation: 1, panopticon_id: FactoryBot.create(:artefact).id, publish_at: Time.zone.now + 1.hour)
            @part = @draft_guide_edition_with_parts.parts.last
            visit confirm_destroy_edition_guide_part_path(@draft_guide_edition_with_parts, @part)
          end

          should "redirect to edit guide page and show a success message when the 'Delete chapter' button is clicked" do
            click_button("Delete chapter")
            @draft_guide_edition_with_parts.reload

            assert_current_path edition_path(@draft_guide_edition_with_parts)
            assert page.has_content?("Chapter deleted successfully")
            assert @draft_guide_edition_with_parts.parts.exclude? @part
          end

          should "direct the user to the edit chapter page when the 'Cancel' button is clicked" do
            click_link("Cancel")
            assert_current_path edit_edition_guide_part_path(@draft_guide_edition_with_parts, @part)
          end
        end
      end

      context "when the 'guide_chapter_accordion_interface' feature toggle is on" do
        setup do
          @test_strategy.switch!(:guide_chapter_accordion_interface, true)
          @draft_guide_edition_with_parts = FactoryBot.create(:guide_edition_with_two_parts, :draft, title: "Edit page title", overview: "metatags", in_beta: 1, hide_chapter_navigation: 1, panopticon_id: FactoryBot.create(:artefact).id, publish_at: Time.zone.now + 1.hour)
          @part_1 = @draft_guide_edition_with_parts.parts.first
          @part_2 = @draft_guide_edition_with_parts.parts.second
          visit edition_path(@draft_guide_edition_with_parts)
        end

        context "user has editor permissions" do
          should "show fields for guide edition" do
            assert_field "Title", with: "Edit page title"
            assert_field "Meta tag description", with: "metatags"

            assert_text "Chapters"
            assert_link "Add a new chapter", href: new_edition_guide_part_path(@draft_guide_edition_with_parts)

            within all(".govuk-fieldset")[0] do
              assert_text "Is every chapter part of a step by step?"
              assert_text "The chapter navigation will be hidden if they all are"
              assert find(".gem-c-radio input[value='1']").checked?
            end

            within all(".govuk-fieldset")[1] do
              assert page.has_css?("legend", text: "Is this beta content?")
              assert find(".gem-c-radio input[value='1']").checked?
            end
          end

          should "show guide chapter list for guide edition if present" do
            assert_field "Title", with: "Edit page title"
            assert_field "Meta tag description", with: "metatags"
            assert_text "Chapters"

            within ".govuk-accordion" do
              within all(".govuk-accordion__section")[0] do
                assert_field "Title", with: @part_1.title
                assert_field "Slug", with: @part_1.slug
                assert_field "Body", with: @part_1.body
                assert_link "Delete chapter", href: confirm_destroy_edition_guide_part_path(@draft_guide_edition_with_parts, @part_1)
              end

              within all(".govuk-accordion__section")[1] do
                assert_field "Title", with: @part_2.title
                assert_field "Slug", with: @part_2.slug
                assert_field "Body", with: @part_2.body
                assert_link "Delete chapter", href: confirm_destroy_edition_guide_part_path(@draft_guide_edition_with_parts, @part_2)
              end
            end

            assert_link "Add a new chapter", href: new_edition_guide_part_path(@draft_guide_edition_with_parts)

            within all(".govuk-fieldset")[0] do
              assert_text "Is every chapter part of a step by step?"
              assert_text "The chapter navigation will be hidden if they all are"
              assert find(".gem-c-radio input[value='1']").checked?
            end

            within all(".govuk-fieldset")[1] do
              assert_text "Is this beta content?"
              assert find(".gem-c-radio input[value='1']").checked?
            end
          end

          should "order guide chapter list by part order attribute" do
            @draft_guide_edition_with_parts.parts.min_by(&:order).update!(order: 5)

            visit edition_path(@draft_guide_edition_with_parts)

            within all(".govuk-accordion__section")[0] do
              assert_text "PART !!"
            end

            within all(".govuk-accordion__section")[1] do
              assert_text "PART !"
            end
          end

          should "update guide edition fields and show success message" do
            visit edition_path(@draft_guide_edition)

            fill_in "Title", with: "Changed Title"
            fill_in "Meta tag description", with: "Changed Meta tag description"

            within all(".govuk-fieldset")[0] do
              choose "Yes"
            end

            within all(".govuk-fieldset")[1] do
              choose "Yes"
            end

            click_button "Save"

            assert_field "Title", with: "Changed Title"
            assert_field "Meta tag description", with: "Changed Meta tag description"

            within all(".govuk-fieldset")[0] do
              assert_text "Is every chapter part of a step by step?"
              assert_text "The chapter navigation will be hidden if they all are"
              assert find(".gem-c-radio input[value='1']").checked?
            end

            within all(".govuk-fieldset")[1] do
              assert_text "Is this beta content?"
              assert find(".gem-c-radio input[value='1']").checked?
            end

            assert_text "Edition updated successfully."
          end

          should "show Add new chapter page when Add new chapter button is clicked" do
            click_link("Add a new chapter")

            assert page.has_content?("Add new chapter")
            assert_field "Title"
            assert_field "Slug"
            assert_field "Body"
          end

          should "not show 'Reorder chapters' button when no parts are present" do
            visit edition_path(@draft_guide_edition)
            assert_no_link "Reorder chapters"
          end

          should "not show 'Reorder chapters' button when 1 part is present" do
            @draft_guide_edition.parts.build(
              title: "PART !",
              body: "This is some version text.",
              slug: "part-one",
              order: 1,
            )
            @draft_guide_edition.save!
            @draft_guide_edition.reload
            visit edition_path(@draft_guide_edition)

            assert_no_link "Reorder chapters"
          end

          should "show an error if the user tries to directly access the reorder chapters page with less than two parts" do
            visit reorder_edition_guide_parts_path(@draft_guide_edition)

            assert current_path == edition_path(@draft_guide_edition)
            assert_text "You can only reorder chapters when there are at least 2."
          end

          should "show 'Reorder chapters' button when two parts are present" do
            assert_link "Reorder chapters", href: reorder_edition_guide_parts_path(@draft_guide_edition_with_parts)
          end

          context "Add new chapter" do
            setup do
              click_link "Add a new chapter"
            end

            should "not show the 'save and go to summary' button" do
              assert_no_button "Save and go to summary"
            end

            should "save and redirect to edit guide page when 'save' button is clicked" do
              fill_in "Title", with: "Part One"
              fill_in "Slug", with: "part-one"
              fill_in "Body", with: "body-text"

              click_button "Save"

              assert_current_path edition_path(@draft_guide_edition_with_parts)
              assert_text "New chapter added successfully."
              assert_field "Title", with: "Part One"
              assert_field "Slug", with: "part-one"
              assert_field "Body", with: "body-text"
            end

            should "show validation error when Title is empty" do
              fill_in "Title", with: ""
              fill_in "Slug", with: "part-one"
              fill_in "Body", with: "body-text"

              click_button "Save"

              assert_current_path edition_guide_parts_path(@draft_guide_edition_with_parts)
              assert_field "Title", with: ""
              assert_field "Slug", with: "part-one"
              assert_field "Body", with: "body-text"
              assert_text "Enter a title"
            end

            should "show validation error when Slug is empty" do
              fill_in "Title", with: "Part one"
              fill_in "Slug", with: ""
              fill_in "Body", with: "body-text"
              click_button "Save"

              assert_current_path edition_guide_parts_path(@draft_guide_edition_with_parts)
              assert_field "Title", with: "Part one"
              assert_field "Slug", with: ""
              assert_field "Body", with: "body-text"
              assert_text "Enter a slug"
            end

            should "show validation error when Slug is invalid" do
              fill_in "Title", with: "Part one"
              fill_in "Slug", with: "@"
              fill_in "Body", with: "body-text"
              click_button "Save"

              assert_current_path edition_guide_parts_path(@draft_guide_edition_with_parts)
              assert_field "Title", with: "Part one"
              assert_field "Slug", with: "@"
              assert_field "Body", with: "body-text"
              assert_text "Slug can only consist of lower case characters, numbers and hyphens"
            end

            should "redirect to guide edit page when back to summary link is clicked" do
              click_link "Back to summary"

              assert_current_path edition_path(@draft_guide_edition_with_parts)
              assert_text "Edit"
            end

            should "display the guide edit page when the 'Cancel and discard changes' link is clicked" do
              click_link "Cancel and discard changes"

              assert_current_path edition_path(@draft_guide_edition_with_parts)
              assert_text "Edit"
            end
          end

          context "Reorder Chapters" do
            setup do
              click_link("Reorder chapters")
            end

            should "reorder chapters and redirect to guide edit page when update order is clicked" do
              within all(".gem-c-reorderable-list__item")[0] do
                fill_in "Position", with: "2"
              end

              within all(".gem-c-reorderable-list__item")[1] do
                fill_in "Position", with: "1"
              end

              click_button "Update order"

              within all(".govuk-accordion__section")[0] do
                assert_text "PART !!"
              end
              within all(".govuk-accordion__section")[1] do
                assert_text "PART !"
              end
            end

            should "not reorder chapters and redirect to guide edit page when cancel is clicked" do
              within all(".gem-c-reorderable-list__item")[0] do
                fill_in "Position", with: "2"
              end
              within all(".gem-c-reorderable-list__item")[1] do
                fill_in "Position", with: "1"
              end

              click_link "Cancel"

              within all(".govuk-accordion__section")[0] do
                assert_text "PART !"
              end
              within all(".govuk-accordion__section")[1] do
                assert_text "PART !!"
              end
            end
          end

          context "Edit chapter" do
            should "update chapter fields and show success message" do
              within all(".govuk-accordion__section")[0] do
                fill_in "Title", with: "Changed chapter title"
                fill_in "Slug", with: "changed-chapter-slug"
                fill_in "Body", with: "Changed chapter body"
              end

              within all(".govuk-accordion__section")[1] do
                fill_in "Title", with: "Different title"
                fill_in "Slug", with: "different-slug"
                fill_in "Body", with: "Different body"
              end

              click_button "Save"

              assert_text "Edition updated successfully."

              within all(".govuk-accordion__section")[0] do
                assert_field "Title", with: "Changed chapter title"
                assert_field "Slug", with: "changed-chapter-slug"
                assert_field "Body", with: "Changed chapter body"
              end

              within all(".govuk-accordion__section")[1] do
                assert_field "Title", with: "Different title"
                assert_field "Slug", with: "different-slug"
                assert_field "Body", with: "Different body"
              end
            end

            should "show multiple validation errors for multiple chapters with correct links" do
              within all(".govuk-accordion__section")[0] do
                fill_in "Title", with: ""
                fill_in "Slug", with: ""
              end

              within all(".govuk-accordion__section")[1] do
                fill_in "Title", with: ""
                fill_in "Slug", with: "***"
              end

              click_button "Save"

              assert_current_path edition_path(@draft_guide_edition_with_parts)

              within all(".govuk-accordion__section")[0] do
                assert_field "Title", with: ""
                assert_field "Slug", with: ""
              end

              within all(".govuk-accordion__section")[1] do
                assert_field "Title", with: ""
                assert_field "Slug", with: "***"
              end

              within ".govuk-error-summary" do
                assert_text "There is a problem"
                assert_link "Enter a title for Chapter 1", href: "#part_1_title"
                assert_link "Enter a slug for Chapter 1", href: "#part_1_slug"
                assert_link "Enter a title for Chapter 2", href: "#part_2_title"
                assert_link "Slug for Chapter 2 can only consist of lower case characters, numbers and hyphens", href: "#part_2_slug"
              end
            end

            should "show validation error when Title is empty" do
              within all(".govuk-accordion__section")[1] do
                fill_in "Title", with: ""
                fill_in "Slug", with: "part-two"
                fill_in "Body", with: "body-text"
              end

              click_button "Save"

              assert_current_path edition_path(@draft_guide_edition_with_parts)

              within all(".govuk-accordion__section")[1] do
                assert_field "Title", with: ""
                assert_field "Slug", with: "part-two"
                assert_field "Body", with: "body-text"
              end

              within ".govuk-error-summary" do
                assert_text "There is a problem"
                assert_link "Enter a title for Chapter 2", href: "#part_2_title"
              end
            end

            should "show validation error when Slug is empty" do
              within all(".govuk-accordion__section")[1] do
                fill_in "Title", with: "Part two"
                fill_in "Slug", with: ""
                fill_in "Body", with: "body-text"
              end

              click_button "Save"

              assert_current_path edition_path(@draft_guide_edition_with_parts)

              within all(".govuk-accordion__section")[1] do
                assert_field "Title", with: "Part two"
                assert_field "Slug", with: ""
                assert_field "Body", with: "body-text"
              end

              within ".govuk-error-summary" do
                assert_text "There is a problem"
                assert_link "Enter a slug for Chapter 2", href: "#part_2_slug"
              end
            end

            should "show validation error when Slug is invalid" do
              within all(".govuk-accordion__section")[1] do
                fill_in "Title", with: "Part two"
                fill_in "Slug", with: "***"
                fill_in "Body", with: "body-text"
              end

              click_button "Save"

              assert_current_path edition_path(@draft_guide_edition_with_parts)

              within all(".govuk-accordion__section")[1] do
                assert_field "Title", with: "Part two"
                assert_field "Slug", with: "***"
                assert_field "Body", with: "body-text"
              end

              within ".govuk-error-summary" do
                assert_text "There is a problem"
                assert_link "Slug for Chapter 2 can only consist of lower case characters, numbers and hyphens", href: "#part_2_slug"
              end
            end

            should "display the Delete chapter confirmation page when the 'Delete chapter' link is clicked" do
              within all(".govuk-accordion__section")[1] do
                click_link "Delete chapter"
              end

              assert_current_path confirm_destroy_edition_guide_part_path(@draft_guide_edition_with_parts, @part_2)
              assert_text "Are you sure you want to delete this chapter?"
            end
          end
        end

        context "user has no editor permissions" do
          setup do
            login_as(FactoryBot.create(:user, name: "Non Editor"))
            visit edition_path(@draft_guide_edition_with_parts)
          end

          should "not show 'Add new chapter' button" do
            assert_no_link "Add a new chapter"
          end

          should "not show 'Reorder chapters' button even with two parts present" do
            assert_no_link "Reorder chapters"
          end

          should "not allow user to load reorder chapters page" do
            visit reorder_edition_guide_parts_path(@draft_guide_edition_with_parts)

            assert current_path == edition_path(@draft_guide_edition_with_parts)
            assert_text "You do not have correct editor permissions for this action."
          end

          should "not show the 'Delete chapter' button'" do
            assert_no_link "Delete chapter"
          end
        end

        context "Delete chapter confirmation" do
          setup do
            visit confirm_destroy_edition_guide_part_path(@draft_guide_edition_with_parts, @part_2)
          end

          should "redirect to edit guide page and show a success message when the 'Delete chapter' button is clicked" do
            click_button "Delete chapter"
            @draft_guide_edition_with_parts.reload

            assert_current_path edition_path(@draft_guide_edition_with_parts)
            assert_text "Chapter deleted successfully"
            assert @draft_guide_edition_with_parts.parts.exclude? @part_2
          end

          should "direct the user to the edit chapter page when the 'Cancel' button is clicked" do
            click_link "Cancel"
            assert_current_path edition_path(@draft_guide_edition_with_parts)
          end
        end
      end
    end

    context "transaction edition" do
      setup do
        @transaction_edition = FactoryBot.create(
          :transaction_edition,
          :draft,
          title: "Edit page title",
          overview: "metatags",
          in_beta: true,
          introduction: "Transaction introduction",
          more_information: "Transaction more information",
          need_to_know: "Transaction need to",
          link: "https://continue.com",
          will_continue_on: "To be continued...",
          alternate_methods: "Method A or B",
          publish_at: nil,
        )
        visit edition_path(@transaction_edition)
      end

      should "show fields for transaction edition" do
        assert page.has_field?("edition[title]", with: "Edit page title")
        assert page.has_css?(".govuk-label", text: "Title")

        assert page.has_field?("edition[overview]", with: "metatags")
        assert page.has_css?(".govuk-label", text: "Meta tag description")
        assert page.has_css?(".govuk-hint", text: "Some search engines will display this if they cannot find what they need in the main text")

        assert page.has_field?("edition[introduction]", with: "Transaction introduction")
        assert page.has_css?(".govuk-label", text: "Introduction")
        assert page.has_css?(".govuk-hint", text: "Set the scene for the user. What is about to happen? For example, “you will need to fill in a form, print it out and take it to the post office”. Refer to the Govspeak guidance (opens in new tab)")

        assert page.has_field?("edition[start_button_text]")
        assert page.has_text?("Start button text")
        assert find(".gem-c-radio input[value='Start now']").checked?

        assert page.has_field?("edition[will_continue_on]", with: "To be continued...")
        assert page.has_css?(".govuk-label", text: "Text below the start button (optional)")
        assert page.has_css?(".govuk-hint", text: "Following ‘on’, for example “the HMRC website”")

        assert page.has_field?("edition[link]", with: "https://continue.com")
        assert page.has_css?(".govuk-label", text: "Link to start of transaction")
        assert page.has_css?(".govuk-hint", text: "Link as deep as possible")

        assert page.has_field?("edition[more_information]", with: "Transaction more information")
        assert page.has_css?(".govuk-label", text: "More information (optional)")

        assert page.has_field?("edition[alternate_methods]", with: "Method A or B")
        assert page.has_css?(".govuk-label", text: "Other ways to apply (optional)")
        assert page.has_css?(".govuk-hint", text: "Alternative ways of completing this transaction")

        assert page.has_field?("edition[need_to_know]", with: "Transaction need to")
        assert page.has_css?(".govuk-label", text: "What you need to know (optional)")

        assert page.has_field?("edition[in_beta]")
        assert page.has_text?("Is this beta content?")
        assert find(".gem-c-radio input[value='1']").checked?
      end

      should "update transaction edition and show success message" do
        fill_in "edition[title]", with: "Changed Title"
        fill_in "edition[overview]", with: "Changed Meta tag description"
        fill_in "edition[introduction]", with: "Changed intro"
        choose("Sign in")
        fill_in "edition[will_continue_on]", with: "Continue on changed"
        fill_in "edition[link]", with: "https://changed.com"
        fill_in "edition[more_information]", with: "Changed more info"
        fill_in "edition[alternate_methods]", with: "Method C or D"
        fill_in "edition[need_to_know]", with: "Changed need to"
        choose("Yes")
        click_button("Save")

        assert page.has_field?("edition[title]", with: "Changed Title")
        assert page.has_field?("edition[overview]", with: "Changed Meta tag description")
        assert page.has_field?("edition[introduction]", with: "Changed intro")
        assert find(".gem-c-radio input[value='Sign in']").checked?
        assert page.has_field?("edition[will_continue_on]", with: "Continue on changed")
        assert page.has_field?("edition[link]", with: "https://changed.com")
        assert page.has_field?("edition[more_information]", with: "Changed more info")
        assert page.has_field?("edition[alternate_methods]", with: "Method C or D")
        assert page.has_field?("edition[need_to_know]", with: "Changed need to")
        assert find(".gem-c-radio input[value='1']").checked?
        assert page.has_text?("Edition updated successfully.")
      end
    end

    context "completed transaction edition" do
      should "show correct fields for no promotion" do
        completed_transaction_edition = FactoryBot.create(
          :completed_transaction_edition,
          :draft,
          title: "Edit page title",
          overview: "metatags",
          body: "completed transaction body",
          presentation_toggles: { promotion_choice: { choice: "none", url: "", opt_in_url: "", opt_out_url: "" } },
          in_beta: true,
          publish_at: nil,
        )

        visit edition_path(completed_transaction_edition)

        assert page.has_field?("edition[title]", with: "Edit page title")
        assert page.has_css?(".govuk-label", text: "Title")
        assert page.has_field?("edition[overview]", with: "metatags")
        assert page.has_css?(".govuk-label", text: "Meta tag description")
        assert page.has_css?(".govuk-hint", text: "Some search engines will display this if they cannot find what they need in the main text")
        assert page.has_text?("Promotions")
        assert page.has_css?(".govuk-hint", text: "Display a promotion above the satisfaction survey")
        assert page.has_checked_field?("edition[promotion_choice]", with: "none")
        assert page.has_field?("edition[in_beta]")
        assert page.has_text?("Is this beta content?")
        assert page.has_checked_field?("edition[in_beta]", with: "1")
      end

      should "show correct fields for organ donation" do
        completed_transaction_edition = FactoryBot.create(
          :completed_transaction_edition,
          :draft,
          presentation_toggles: { promotion_choice: { choice: "organ_donor", url: "https://example.com", opt_in_url: "https://opt-in.com", opt_out_url: "https://opt-out.com" } },
        )

        visit edition_path(completed_transaction_edition)

        assert page.has_checked_field?("edition[promotion_choice]", with: "organ_donor")
        assert page.has_css?(".govuk-label", text: "Promotion URL")
        assert page.has_field?("edition[promotion_choice_url_organ_donor]", with: "https://example.com")
        assert page.has_css?(".govuk-label", text: "Opt-in URL (optional)")
        assert page.has_field?("edition[promotion_choice_opt_in_url]", with: "https://opt-in.com")
        assert page.has_css?(".govuk-label", text: "Opt-out URL (optional)")
        assert page.has_field?("edition[promotion_choice_opt_out_url]", with: "https://opt-out.com")
      end

      should "show correct fields for photo ID" do
        completed_transaction_edition = FactoryBot.create(
          :completed_transaction_edition,
          :draft,
          presentation_toggles: { promotion_choice: { choice: "bring_id_to_vote", url: "https://example.com", opt_in_url: "", opt_out_url: "" } },
        )

        visit edition_path(completed_transaction_edition)

        assert page.has_checked_field?("edition[promotion_choice]", with: "bring_id_to_vote")
        assert page.has_css?(".govuk-label", text: "Promotion URL")
        assert page.has_field?("edition[promotion_choice_url_bring_id_to_vote]", with: "https://example.com")
      end

      should "show correct fields for MOT reminder" do
        completed_transaction_edition = FactoryBot.create(
          :completed_transaction_edition,
          :draft,
          presentation_toggles: { promotion_choice: { choice: "mot_reminder", url: "https://example.com", opt_in_url: "", opt_out_url: "" } },
        )

        visit edition_path(completed_transaction_edition)

        assert page.has_checked_field?("edition[promotion_choice]", with: "mot_reminder")
        assert page.has_css?(".govuk-label", text: "Promotion URL")
        assert page.has_field?("edition[promotion_choice_url_mot_reminder]", with: "https://example.com")
      end

      should "show correct fields for electric vehicles" do
        completed_transaction_edition = FactoryBot.create(
          :completed_transaction_edition,
          :draft,
          presentation_toggles: { promotion_choice: { choice: "electric_vehicle", url: "https://example.com", opt_in_url: "", opt_out_url: "" } },
        )

        visit edition_path(completed_transaction_edition)

        assert page.has_checked_field?("edition[promotion_choice]", with: "electric_vehicle")
        assert page.has_css?(".govuk-label", text: "Promotion URL")
        assert page.has_field?("edition[promotion_choice_url_electric_vehicle]", with: "https://example.com")
      end

      should "amend fields and show success message when edition is updated" do
        completed_transaction_edition = FactoryBot.create(
          :completed_transaction_edition,
          :draft,
          presentation_toggles: { promotion_choice: { choice: "none", url: "", opt_in_url: "", opt_out_url: "" } },
        )

        visit edition_path(completed_transaction_edition)
        fill_in "edition[title]", with: "Changed Title"
        fill_in "edition[overview]", with: "Changed Meta tag description"
        choose("Organ donation")
        fill_in "edition[promotion_choice_url_organ_donor]", with: "https://organ.com"
        fill_in "edition[promotion_choice_opt_in_url]", with: "https://organ_opt_in.com"
        fill_in "edition[promotion_choice_opt_out_url]", with: "https://organ_opt_out.com"
        choose("Yes")
        click_button("Save")

        assert page.has_field?("edition[title]", with: "Changed Title")
        assert page.has_field?("edition[overview]", with: "Changed Meta tag description")
        assert page.has_field?("edition[promotion_choice_url_organ_donor]", with: "https://organ.com")
        assert page.has_field?("edition[promotion_choice_url_bring_id_to_vote]", with: "")
        assert page.has_field?("edition[promotion_choice_url_mot_reminder]", with: "")
        assert page.has_field?("edition[promotion_choice_url_electric_vehicle]", with: "")
        assert page.has_field?("edition[promotion_choice_opt_in_url]", with: "https://organ_opt_in.com")
        assert page.has_field?("edition[promotion_choice_opt_out_url]", with: "https://organ_opt_out.com")
        assert page.has_checked_field?("edition[promotion_choice]", with: "organ_donor")
        assert page.has_checked_field?("edition[in_beta]", with: "1")
        assert page.has_text?("Edition updated successfully.")

        choose("Bring photo ID to vote")
        fill_in "edition[promotion_choice_url_bring_id_to_vote]", with: "https://photo.com"
        click_button("Save")

        assert page.has_field?("edition[promotion_choice_url_bring_id_to_vote]", with: "https://photo.com")
        assert page.has_field?("edition[promotion_choice_url_organ_donor]", with: "")
        assert page.has_field?("edition[promotion_choice_opt_in_url]", with: "")
        assert page.has_field?("edition[promotion_choice_opt_out_url]", with: "")
        assert page.has_checked_field?("edition[promotion_choice]", with: "bring_id_to_vote")

        choose("MOT reminders")
        fill_in "edition[promotion_choice_url_mot_reminder]", with: "https://mot.com"
        click_button("Save")

        assert page.has_field?("edition[promotion_choice_url_bring_id_to_vote]", with: "")
        assert page.has_field?("edition[promotion_choice_url_mot_reminder]", with: "https://mot.com")
        assert page.has_checked_field?("edition[promotion_choice]", with: "mot_reminder")

        choose("Electric vehicles")
        fill_in "edition[promotion_choice_url_electric_vehicle]", with: "https://electric.com"
        click_button("Save")

        assert page.has_field?("edition[promotion_choice_url_mot_reminder]", with: "")
        assert page.has_field?("edition[promotion_choice_url_electric_vehicle]", with: "https://electric.com")
        assert page.has_checked_field?("edition[promotion_choice]", with: "electric_vehicle")
      end

      should "raise an error and not save changes if Promotion URL is not filled out" do
        ["Organ donation", "Bring photo ID to vote", "MOT reminders", "Electric vehicles"].each do |promotion_choice|
          completed_transaction_edition = FactoryBot.create(
            :completed_transaction_edition,
            :draft,
            presentation_toggles: { promotion_choice: { choice: "none", url: "", opt_in_url: "", opt_out_url: "" } },
          )

          visit edition_path(completed_transaction_edition)
          choose(promotion_choice)
          click_button("Save")

          assert page.has_css?(".gem-c-error-summary__list-item", text: "Enter a promotion URL")
          assert page.has_css?(".govuk-error-message", text: "Enter a promotion URL")
          assert page.has_css?(".govuk-input--error")
        end
      end
    end
  end

  context "draft edition of a previously published publication" do
    setup do
      @published_edition = FactoryBot.create(:edition, :published)
      @new_edition = FactoryBot.create(:edition, :draft, panopticon_id: @published_edition.artefact.id)
      visit edition_path(@new_edition)
    end

    should "show Change Note field for a new edition of a published document" do
      find("details").click
      find("input[name='edition[major_change]'][value='true']").choose

      assert page.has_text?("Add a public change note")
      assert page.has_text?("Telling users when published information has changed is important for transparency.")
      assert page.has_field?("edition[change_note]")
    end
  end
end
