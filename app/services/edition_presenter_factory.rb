class EditionPresenterFactory
  class << self
    def get_presenter(edition)
      presenter_class(edition.editionable_class.to_s).constantize.new(edition)
    end

    def presenter_class(editionable_class)
      case editionable_class
      when "AnswerEdition"
        "Formats::AnswerPresenter"
      when "CompletedTransactionEdition"
        "Formats::CompletedTransactionPresenter"
      when "GuideEdition"
        "Formats::GuidePresenter"
      when "HelpPageEdition"
        "Formats::HelpPagePresenter"
      when "LocalTransactionEdition"
        "Formats::LocalTransactionPresenter"
      when "PlaceEdition"
        "Formats::PlacePresenter"
      when "SimpleSmartAnswerEdition"
        "Formats::SimpleSmartAnswerPresenter"
      when "TransactionEdition"
        "Formats::TransactionPresenter"
      when "PopularLinksEdition"
        "Formats::PopularLinksPresenter"
      else
        "Formats::GenericEditionPresenter"
      end
    end
  end
end
