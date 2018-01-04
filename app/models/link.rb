class Link
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :link_check_report

  field :uri, type: String
  field :status, type: String
  field :checked_at, type: DateTime
  field :check_warnings, type: Array
  field :check_errors, type: Array
  field :problem_summary, type: String
  field :suggested_fix, type: String

  validates :uri, presence: true
  validates :status, presence: true
end
