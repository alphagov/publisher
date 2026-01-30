class NewDesignSystemConstraint
  def matches?(request)
    allowed_content_types = [
      AnswerEdition,
      HelpPageEdition,
      PlaceEdition,
      TransactionEdition,
      CompletedTransactionEdition,
      LocalTransactionEdition,
      GuideEdition,
    ]

    AllowedContentTypesConstraint.new(allowed_content_types).matches?(request)
  end
end
