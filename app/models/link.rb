class Link < ApplicationRecord
  belongs_to :link_check_report, inverse_of: :links

  validates :uri, presence: true
  validates :status, presence: true
end
