class EditionPresenterFactory
  class << self
    def get_presenter(edition)
      presenter_class(edition.class.to_s).constantize.new(edition)
    end

    def presenter_class(edition_class)
      case edition_class
      when "AnswerEdition"
        "Formats::AnswerPresenter"
      when "GuideEdition"
        "Formats::GuidePresenter"
      when "HelpPageEdition"
        "Formats::HelpPagePresenter"
      when "LocalTransactionEdition"
        "Formats::LocalTransactionPresenter"
      else
        "Formats::GenericEditionPresenter"
      end
    end
  end
end
