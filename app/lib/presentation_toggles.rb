module PresentationToggles
  extend ActiveSupport::Concern

  included do
    field :presentation_toggles, type: Hash, default: default_presentation_toggles
    validates :promotion_choice_url, presence: true, if: :promotes_something?
    validates :promotion_choice, inclusion: { in: %w[none organ_donor bring_id_to_vote mot_reminder electric_vehicle] }
  end

  def promotion_choice=(value)
    promotion_choice_key["choice"] = value
  end

  def promotion_choice_url=(value)
    promotion_choice_key["url"] = value
  end

  def promotion_choice_opt_in_url=(value)
    promotion_choice_key["opt_in_url"] = value
  end

  def promotion_choice_opt_out_url=(value)
    promotion_choice_key["opt_out_url"] = value
  end

  def promotion_choice
    choice = promotion_choice_key["choice"]
    choice.empty? ? "none" : choice
  end

  def promotes_something?
    promotion_choice != "none"
  end

  def promotion_choice_url
    promotion_choice_key["url"]
  end

  def promotion_choice_opt_in_url
    promotion_choice_key["opt_in_url"]
  end

  def promotion_choice_opt_out_url
    promotion_choice_key["opt_out_url"]
  end

  def promotion_choice_key
    unless presentation_toggles.key? "promotion_choice"
      presentation_toggles["promotion_choice"] = self.class.default_presentation_toggles["promotion_choice"]
    end

    presentation_toggles["promotion_choice"]
  end

  module ClassMethods
    def default_presentation_toggles
      {
        "promotion_choice" =>
          {
            "choice" => "none",
            "url" => "",
          },
      }
    end
  end
end
