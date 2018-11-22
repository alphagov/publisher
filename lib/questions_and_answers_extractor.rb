class QuestionsAndAnswersExtractor

  def get_pairs_from_editions
    published_editions = Edition.where(state: 'published')

    published_editions.map do |edition|
      QuestionAndAnswerPresenter.new(edition.body, edition.slug).pairs
    end
  end
end