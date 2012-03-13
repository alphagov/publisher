class TransactionEdition < WholeEdition

  include Expectant

  field :introduction,      :type => String
  field :will_continue_on,  :type => String
  field :link,              :type => String
  field :more_information,  :type => String
  field :alternate_methods,  :type => String

  @fields_to_clone = [:introduction, :will_continue_on, :link, :more_information, :alternate_methods, :minutes_to_complete, :uses_government_gateway, :expectation_ids]

  def indexable_content
    content = super
    return content unless latest_edition?
    "#{content} #{introduction} #{more_information}".strip
  end

  def whole_body
    [ self.link, self.introduction, self.more_information ].join("\n\n")
  end
end
