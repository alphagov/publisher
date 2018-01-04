class LinkCheckReport
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :edition
  embeds_many :links

  accepts_nested_attributes_for :links

  field :batch_id, type: Integer
  field :status, type: String
  field :completed_at, type: DateTime

  validates :batch_id, presence: true, uniqueness: true
  validates :status, presence: true
  validates :links, presence: true
end
