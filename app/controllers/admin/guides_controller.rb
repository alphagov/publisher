class Admin::GuidesController <  Admin::PublicationSubclassController

private
  def resource_path(r)
    admin_guide_path(r)
  end

  def create_new
    current_user.create_guide(params[:guide])
  end
end
