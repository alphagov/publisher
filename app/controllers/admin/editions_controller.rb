class Admin::EditionsController < Admin::BaseController
  actions :create, :update, :destroy
  defaults :resource_class => WholeEdition, :collection_name => 'editions', :instance_name => 'edition'

  def create
    new_edition = current_user.new_version(resource)
    assigned_to_id = (params[:edition] || {}).delete(:assigned_to_id)
    if new_edition and new_edition.save
      update_assignment new_edition, assigned_to_id
      redirect_to params[:return_to] and return if params[:return_to]
      redirect_to admin_edition_path(new_edition), :notice => 'New edition created'
    else
      alert = 'Failed to create new edition'
      alert += new_edition ? ": #{new_edition.errors.inspect}" : ": couldn't initialise"
      redirect_to admin_edition_path(resource), :alert => alert
    end
  end

  def update
    assigned_to_id = (params[:edition] || {}).delete(:assigned_to_id)
    update! do |success, failure|
      success.html {
        update_assignment resource, assigned_to_id
        redirect_to params[:return_to] and return if params[:return_to]
        redirect_to [:admin, resource]
      }
      failure.html {
        prepend_view_path "app/views/admin/publication_subclasses"
        prepend_view_path admin_template_folder_for(resource)
        @resource = resource
        
        flash.now[:alert] = "We had some problems saving. Please check the form below."

        render :template => "show"

      }
      success.json {
        update_assignment resource, assigned_to_id
        render :json => resource
      }
      failure.json { render :json => resource.errors, :status=>406 }
    end
  end

  def start_work
    if resource.progress({request_type: 'start_work'}, current_user)
      redirect_to admin_edition_path(resource), :notice => "Work started on #{description(resource)}"
    else
      redirect_to admin_edition_path(resource), :alert => "Couldn't start work on #{description(resource).downcase}"
    end
  end

  def progress
    if resource.progress(params[:activity].dup, current_user)
      redirect_to admin_edition_path(resource), :notice => "#{description(resource)} updated"
    else
      redirect_to admin_edition_path(resource), :alert => "Couldn't #{params[:activity][:request_type].to_s.humanize.downcase} for #{description(resource).downcase}"
    end
  end

  def skip_fact_check
    if resource.progress({request_type: 'receive_fact_check', comment: "Fact check skipped by request."}, current_user)
      redirect_to admin_edition_path(resource), :notice => "The fact check has been skipped for this publication."
    else
      redirect_to admin_edition_path(resource), :alert => "Could not skip fact check for this publication."
    end
  end

  protected
    def update_assignment(edition, assigned_to_id)
      return if assigned_to_id.blank?
      assigned_to = User.find(assigned_to_id)
      return if edition.assigned_to == assigned_to
      current_user.assign(edition, assigned_to)
    end
end
