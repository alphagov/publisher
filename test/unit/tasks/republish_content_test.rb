require "test_helper"
require "rake"

class RepublishContentTest < ActiveSupport::TestCase
  setup do
    @published_edition = FactoryGirl.create(:answer_edition, state: 'published')
    draft_artefact = FactoryGirl.create(:draft_artefact, kind: 'help_page', slug: 'help/me')
    @draft_edition = FactoryGirl.create(:help_page_edition, state: 'draft', panopticon_id: draft_artefact.id)
  end

  context "#publishing_api:republish_content" do
    should "republish both draft and published editions" do
      PublishingAPIRepublisher.expects(:perform_async).with(@published_edition.id.to_s)
      UpdateWorker.expects(:perform_async).with(@draft_edition.id.to_s)

      # This is to prevent the rake task ouputting to the console
      silence_stream(STDOUT) do
        silence_stream(STDERR) do
          Rake::Task['publishing_api:republish_content'].invoke
        end
      end
    end
  end

  context "#publishing_api:republish_by_format" do
    should "only republish items of that format" do
      UpdateWorker.expects(:perform_async).with(@draft_edition.id.to_s)

      # This is to prevent the rake task ouputting to the console
      silence_stream(STDOUT) do
        silence_stream(STDERR) do
          Rake::Task['publishing_api:republish_by_format'].invoke('help_page')
        end
      end
    end
  end
end
