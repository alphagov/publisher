class ArtefactAction
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field "action_type", type: String
  field "snapshot", type: Hash
  field "task_performed_by", type: String

  embedded_in :artefact

  # Ideally we would like to use the UID field here, since that will be the
  # same across all applications, but Mongoid doesn't yet support using a
  # custom primary key on a related field
  belongs_to :user, optional: true

  # Not validating presence of a user just yet, since there may be some
  # circumstances where we can't reliably determine the user. As an example
  # of this, requests made through the API are not yet tied to a user. If we
  # find out that there are no such circumstances in practice, we can add a
  # validator for :user.
  validates_presence_of :action_type, :snapshot
end
