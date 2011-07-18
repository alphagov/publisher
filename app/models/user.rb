class User
  include Mongoid::Document
  include GDS::SSO::User
  
  field  :uid, :type => String
  field  :email, :type => String
  field  :version, :type => Integer
  field  :name, :type => String

  def self.find_by_uid(uid)
    first(conditions: {uid: uid})
  end

  def record_action(edition,type,comment=nil)
    action = edition.new_action(self, type, comment)
    NoisyWorkflow.make_noise(edition.container,action).deliver
  end
  
  def create_guide(attributes = {})
    guide = Guide.new(attributes)
    record_action guide.editions.first, Action::CREATED
    guide
  end

  def create_answer(attributes = {})
     answer = Answer.new(attributes)
     record_action answer.editions.first, Action::CREATED
     answer
   end

  def new_version(edition)
    new_edition = edition.build_clone
    record_action new_edition, Action::NEW_VERSION
    new_edition
  end

  def request_review(edition, comment)
    record_action edition, Action::REVIEW_REQUESTED, comment
    edition
  end

  def review(edition,comment)
    record_action edition, Action::REVIEWED, comment
    edition
  end

  def okay(edition,comment)
    record_action edition, Action::OKAYED, comment
    edition
  end

  def publish(edition,notes)
    record_action edition, Action::PUBLISHED
    edition.publish(edition,notes)
    edition
  end

  def to_s
    name
  end
end