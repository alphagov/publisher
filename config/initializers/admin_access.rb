class CanAccessFlipperUI
  def self.matches?(request)    
    current_user = request.env['warden'].user
    current_user.present? && current_user.govuk_editor?
  end
end