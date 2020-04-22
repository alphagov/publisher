class UpdateBetaBooleanToPhaseString < Mongoid::Migration
  def self.up
    Edition.where(in_beta: true).update_all(phase: "beta")
  end

  def self.down
    Edition.where(phase: "beta").update_all(in_beta: true)
  end
end
