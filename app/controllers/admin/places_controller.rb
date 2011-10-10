class Admin::PlacesController < Admin::PublicationSubclassController

private
  def resource_path(r)
    admin_place_path(r)
  end

  def create_new
    current_user.create_place(params[:place])
  end
end
