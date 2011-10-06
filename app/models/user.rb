class User
  include Mongoid::Document
  include GDS::SSO::User

  cache

  field  :uid, :type => String
  field  :email, :type => String
  field  :version, :type => Integer
  field  :name, :type => String

  def self.find_by_uid(uid)
    first(conditions: {uid: uid})
  end

  def record_action(edition, type, options={})
    action = edition.new_action(self, type, options)
    NoisyWorkflow.make_noise(edition.container,action).deliver
  end
  
  def record_note(edition, comment)
    edition.new_action(self, 'note', comment: comment)
  end

  def create_publication(kind_class, attributes = {})
    item = kind_class.new(attributes)
    record_action item.editions.first, Action::CREATED
    item
  end

  def create_place(attributes = {})
    create_publication(Place, attributes)
  end

  def create_local_transaction(attributes = {})
    create_publication(LocalTransaction, attributes)
  end

  def create_transaction(attributes = {})
    create_publication(Transaction, attributes)
  end

  def create_guide(attributes = {})
    create_publication(Guide, attributes)
  end

  def create_programme(attributes = {})
    create_publication(Programme, attributes)
  end

  def create_answer(attributes = {})
    create_publication(Answer, attributes)
  end

  def new_version(edition)
    return false unless edition.is_published?

    new_edition = edition.build_clone
    if new_edition
      record_action new_edition, Action::NEW_VERSION
      new_edition
    else
      false
    end
  end

  def request_fact_check(edition, email_addresses)
    record_action edition, Action::FACT_CHECK_REQUESTED, comment: email_addresses
    NoisyWorkflow.request_fact_check(edition, email_addresses).deliver
    edition
  end

  def request_review(edition, comment)
    #return false if edition.status_is?(Action::REVIEW_REQUESTED)
    record_action edition, Action::REVIEW_REQUESTED, comment: comment
    edition
  end

  def receive_fact_check(edition, comment)
    record_action edition, Action::FACT_CHECK_RECEIVED, comment: comment
    edition
  end

  def review(edition, comment)
    #return false if edition.latest_status_action.requester_id == self.id

    edition.container.mark_as_rejected

    record_action edition, Action::REVIEWED, comment: comment
    edition
  end

  def okay(edition, comment)
    #return false if edition.latest_status_action.requester_id == self.id

    edition.container.mark_as_accepted
    record_action edition, Action::OKAYED, comment: comment
    edition
  end

  def publish(edition, notes)
    record_action edition, Action::PUBLISHED
    edition.publish(edition,notes)
    edition
  end

  def assign(edition, recipient)
    record_action edition, Action::ASSIGNED, recipient: recipient
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
