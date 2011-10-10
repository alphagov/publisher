class Admin::ProgrammesController <  Admin::PublicationSubclassController

private
  def resource_path(r)
    admin_programme_path(r)
  end

  def create_new
    current_user.create_programme(params[:programme])
  end
end
