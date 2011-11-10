class User
  include Mongoid::Document
  include GDS::SSO::User

  cache

  field  :uid, :type => String
  field  :email, :type => String
  field  :version, :type => Integer
  field  :name, :type => String

  scope :alphabetized, order_by(name: :asc)

  def self.find_by_uid(uid)
    first(conditions: {uid: uid})
  end

  def record_action(edition, type, options={})
    action = edition.new_action(self, type, options)
    messenger_topic = action.to_s.downcase
    Messenger.instance.messenger_topic edition.container
    NoisyWorkflow.make_noise(edition.container,action).deliver
  end
  
  def record_note(edition, comment)
    edition.new_action(self, 'note', comment: comment)
  end

  PUBLICATION_CLASSES = {
    :place             => Place,
    :local_transaction => LocalTransaction,
    :transaction       => Transaction,
    :guide             => Guide,
    :programme         => Programme,
    :answer            => Answer,
  }

  def create_publication(kind, attributes = {})
    item = PUBLICATION_CLASSES[kind].new(attributes)
    record_action item.editions.first, Action::CREATED
    item
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

  def start_work(edition)
    edition.container.mark_as_started
    record_action edition, Action::WORK_STARTED
    true
  end

  def request_fact_check(edition, details)
    return false if details[:email_addresses].blank?
    note_text = "\n\nResponses should be sent to: " + edition.fact_check_email_address
    if details[:comment].blank?
      details[:comment] = "Fact check requested" + note_text
    else
      details[:comment] += note_text
    end
    record_action edition, Action::FACT_CHECK_REQUESTED, details
    NoisyWorkflow.request_fact_check(edition, details).deliver
    edition
  end

  def request_review(edition, details)
    return false if edition.status_is?(Action::REVIEW_REQUESTED)
    record_action edition, Action::REVIEW_REQUESTED, details
    edition
  end

  def receive_fact_check(edition, details)
    record_action edition, Action::FACT_CHECK_RECEIVED, details 
    edition
  end

  def review(edition, details)
    return false if edition.latest_status_action.requester_id == self.id

    edition.container.mark_as_rejected
    record_action edition, Action::REVIEWED, details
    edition
  end

  def okay(edition, details)
    return false if edition.latest_status_action.requester_id == self.id

    edition.container.mark_as_accepted
    record_action edition, Action::OKAYED, details
    edition
  end

  def publish(edition, details)
    record_action edition, Action::PUBLISHED, details
    edition.publish(edition, details[:comment])
    edition
  end

  def assign(edition, recipient)
    record_action edition, Action::ASSIGNED, recipient: recipient
  end

  def to_s
    name || ""
  end

  def gravatar_url(opts = {})
    opts.symbolize_keys!
    qs = opts.select { |k, v| k == :s }.collect { |k, v| "#{k}=#{Rack::Utils.escape(v)}" }.join("&")
    qs = "?" + qs unless qs == ""
    scheme_and_host = opts[:ssl] ? "https://secure.gravatar.com" : "http://www.gravatar.com"
    "#{scheme_and_host}/avatar/#{Digest::MD5.hexdigest(email.downcase)}#{qs}"
  end
end
