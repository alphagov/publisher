class ReviewerValidator < ActiveModel::Validator
  def validate(record)
    if record.reviewer
      validate_reviewer_in_review(record)
      validate_reviewer_not_assignee(record)
    end
  end

private

  def validate_reviewer_in_review(record)
    unless record.in_review?
      record.errors.add(:reviewer, "can only be set when in review")
    end
  end

  def validate_reviewer_not_assignee(record)
    if record.assigned_to && record.reviewer == record.assigned_to.name
      record.errors.add(:reviewer, "can't be the assignee")
    end
  end
end
