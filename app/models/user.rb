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
    return false unless edition.is_published?

    new_edition = edition.build_clone
    record_action new_edition, Action::NEW_VERSION
    new_edition
  end

  def request_review(edition, comment)
    record_action edition, Action::REVIEW_REQUESTED, comment
    edition
  end

  def review(edition,comment)
    return false if edition.latest_action.requester_id == self.id

    record_action edition, Action::REVIEWED, comment
    edition
  end

  def okay(edition,comment)
    return false if edition.latest_action.requester_id == self.id
    
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
  
  def gravatar_url(opts = {})
    opts.symbolize_keys!
    qs = opts.select { |k, v| k == :s }.collect { |k, v| "#{k}=#{Rack::Utils.escape(v)}" }.join("&")
    qs = "?" + qs unless qs == ""
    scheme_and_host = opts[:ssl] ? "https://secure.gravatar.com" : "http://www.gravatar.com"
    "#{scheme_and_host}/avatar/#{Digest::MD5.hexdigest(email.downcase)}#{qs}"
  end
end