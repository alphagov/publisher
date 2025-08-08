class LinkCheckReport < ApplicationRecord
  belongs_to :edition
  has_many :links, dependent: :destroy

  accepts_nested_attributes_for :links

  # rubocop/disable Rails/UniqueValidationWithoutIndex
  validates :batch_id, presence: true, uniqueness: true
  # rubocop/enable Rails/UniqueValidationWithoutIndex
  #
  validates :status, presence: true
  validates :links, presence: true

  def completed?
    status == "completed"
  end

  def in_progress?
    !completed?
  end

  def broken_links
    links.select { |l| l.status == "broken" }
  end

  def caution_links
    links.select { |l| l.status == "caution" }
  end
end
