class NewDesignSystemConstraint
  def matches?(request)
    design_system_edit_phase_1(request) || design_system_edit_phase_2(request) || design_system_edit_phase_3a(request)
  end

  def design_system_edit_phase_1(request)
    phase_1_content_types = [
      AnswerEdition,
      HelpPageEdition,
    ]

    AllowedContentTypesConstraint.new(phase_1_content_types).matches?(request)
  end

  def design_system_edit_phase_2(request)
    phase_2_content_types = [
      PlaceEdition,
      TransactionEdition,
      CompletedTransactionEdition,
      LocalTransactionEdition,
    ]

    AllowedContentTypesConstraint.new(phase_2_content_types).matches?(request)
  end

  def design_system_edit_phase_3a(request)
    phase_3a_content_types = [
      GuideEdition,
    ]

    AllowedContentTypesConstraint.new(phase_3a_content_types).matches?(request) && FeatureConstraint.new("design_system_edit_phase_3a").matches?(request)
  end
end
