require 'csv'

class LocalTransactionsSource
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  has_many :lgsls, class_name: "LocalTransactionsSource::Lgsl" do
    def find_by_lgsl(lgsl_code)
      where(code: lgsl_code).first
    end
  end

  def self.current
    self.first(sort: [[:created_at, :desc]])
  end

  def self.find_current_lgsl(lgsl_code)
    current.lgsls.find_by_lgsl(lgsl_code)
  end
end
