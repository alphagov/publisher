class ArtefactAction < ApplicationRecord
  belongs_to :artefact
  belongs_to :user, optional: true

  # Not validating presence of a user just yet, since there may be some
  # circumstances where we can't reliably determine the user. As an example
  # of this, requests made through the API are not yet tied to a user. If we
  # find out that there are no such circumstances in practice, we can add a
  # validator for :user.
  validates :action_type, :snapshot, presence: true
end
