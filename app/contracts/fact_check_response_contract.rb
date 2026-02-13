class FactCheckResponseContract < Dry::Validation::Contract
  json do
    required(:edition_id).filled(:string)
    required(:responder_name).filled(:string)
    required(:accepted).filled(:bool)
    optional(:comment).filled(:string)
  end

  rule(:comment, :accepted) do
    if !values[:accepted] && values[:comment].nil?
      key.failure("must be provided if the fact check is rejected")
    end
  end
end
