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
  
  def create_publication(kind_class, attributes = {})
    item = kind_class.new(attributes)
    record_action item.editions.first, Action::CREATED
    item
  end
  
  def create_transaction(attributes = {})
    create_publication(Transaction, attributes)
  end
      
  def create_guide(attributes = {})
    create_publication(Guide, attributes)
  end

  def create_answer(attributes = {})
    create_publication(Answer, attributes)
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