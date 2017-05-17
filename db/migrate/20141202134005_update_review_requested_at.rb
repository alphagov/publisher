class UpdateReviewRequestedAt < Mongoid::Migration
  def self.up
    Edition.in_review.each do |edition|
      request_review_action = edition.actions.where(request_type: Action::REQUEST_REVIEW).last
      if request_review_action
        edition.update_attribute(:review_requested_at, request_review_action.created_at)
      end
    end
  end

  def self.down
    Edition.in_review.each do |edition|
      edition.update_attribute(:review_requested_at, nil)
    end
  end
end
