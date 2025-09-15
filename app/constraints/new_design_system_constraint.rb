class NewDesignSystemConstraint
  def matches?(request)
    AllowedContentTypesConstraint.new([AnswerEdition,
                                       HelpPageEdition,
                                       PlaceEdition,
                                       TransactionEdition]).matches?(request) && FeatureConstraint.new("design_system_edit").matches?(request)
  end
end
