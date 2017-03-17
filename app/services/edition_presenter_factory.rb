class EditionPresenterFactory
  class << self
    def get_presenter(edition)
      presenter_class(edition.class.to_s).constantize.new(edition)
    end

    def presenter_class(edition_class)
      case edition_class
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
      when "LicenceEdition"
        "Formats::LicencePresenter"
      when "PlaceEdition"
        "Formats::PlacePresenter"
      when "SimpleSmartAnswerEdition"
        "Formats::SimpleSmartAnswerPresenter"
      when "TransactionEdition"
        "Formats::TransactionPresenter"
      else
        "Formats::GenericEditionPresenter"
      end
    end
  end
end
