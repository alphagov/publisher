class NewDesignSystemConstraint
  DESIGN_SYSTEM_CONTENT_TYPES = [AnswerEdition,
                                 HelpPageEdition,
                                 PlaceEdition,
                                 TransactionEdition].freeze
  def matches?(request)
    AllowedContentTypesConstraint.new(DESIGN_SYSTEM_CONTENT_TYPES).matches?(request) && FeatureConstraint.new("design_system_edit").matches?(request)
  end
end
