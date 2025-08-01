class Link < ApplicationRecord
  belongs_to :link_check_report

  validates :uri, presence: true
  validates :status, presence: true
end
