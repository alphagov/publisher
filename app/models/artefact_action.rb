class ArtefactAction
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field "action_type", type: String
  field "snapshot", type: Hash
  field "task_performed_by", type: String

  # Temp-to-be-removed
  # This will be removed once we move artefact_action table to postgres, this temporarily
  # allows to support the belongs_to relation between artefact_action and user
  field "user_id", type: BSON::ObjectId

  embedded_in :artefact

  # Ideally we would like to use the UID field here, since that will be the
  # same across all applications, but Mongoid doesn't yet support using a
  # custom primary key on a related field

  # Temp-to-be-brought-back
  # Currently we are using user_id as a field to store the user_id
  # to bypass the issue of having a belongs_to between a postgres table and a mongo table
  # we will most likely bring back the belongs_to relationship once we move artefact_action table to postgres.

  # belongs_to :user, optional: true

  def user
    User.find(user_id) if user_id
  end

  # Not validating presence of a user just yet, since there may be some
  # circumstances where we can't reliably determine the user. As an example
  # of this, requests made through the API are not yet tied to a user. If we
  # find out that there are no such circumstances in practice, we can add a
  # validator for :user.
  validates :action_type, :snapshot, presence: true
end
