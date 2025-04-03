class LinkCheckReport < ApplicationRecord
  belongs_to :edition, inverse_of: :link_check_reports
  has_many :links, inverse_of: :link_check_report

  accepts_nested_attributes_for :links

  validates :batch_id, presence: true, uniqueness: true
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
