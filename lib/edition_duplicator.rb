class EditionDuplicator
  attr_accessor :existing_edition, :actor, :new_edition

  # existing_edition: The existing edition to be duplicated
  # actor:            The WorkflowActor (usually a user) to perform the action
  def initialize(existing_edition, actor)
    self.existing_edition = existing_edition
    self.actor            = actor
  end

  # This method intentionally skips validations
  def duplicate(new_format = nil, assign_to = nil)
    self.new_edition = actor.new_version(existing_edition, new_format)

    if new_edition && new_edition.save(validate: false)
      update_assignment(assign_to)

      if new_format.present?
        new_edition.artefact.kind = new_edition.kind_for_artefact
        new_edition.artefact.save!(validate: false)
      end

      true
    else
      false
    end
  end

  def error_message
    unless new_edition.is_a?(Edition) && new_edition.errors.empty?
      alert = "Failed to create new edition"
      alert += new_edition ? ": #{new_edition.errors.inspect}" : ": couldn't initialise"
      alert
    end
  end

protected

  def update_assignment(assign_to)
    if assign_to
      actor.assign(new_edition, assign_to)
    end
  end
end
