class Admin::EditionsController < Admin::BaseController
  actions :create, :update, :destroy
  defaults :resource_class => WholeEdition, :collection_name => 'editions', :instance_name => 'edition'
  before_filter :setup_view_paths, :except => [:index, :new, :create]

  def index
    redirect_to admin_root_path
  end

  def show
    @resource = resource
    render :template => 'show'
  end

  def new
    @publication = build_resource
    setup_view_paths_for(@publication)
  end

  def create
    class_identifier = params[:edition].delete(:kind).to_sym
    @publication = current_user.create_whole_edition(class_identifier, params[:edition])
    setup_view_paths_for(@publication)
    if @publication.persisted?
      redirect_to admin_edition_path(@publication),
        :notice => "#{description(@publication)} successfully created"
      return
    else
      render :action => "new"
    end
  end

  def duplicate
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
        redirect_to admin_edition_path(resource)
      }
      failure.html {
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

  def destroy
    if resource.can_destroy?
      destroy! do
        redirect_to admin_root_url, :notice => "#{description(resource)} destroyed"
        return
      end
    else
      redirect_to admin_edition_path(resource),
        :notice => "Cannot delete a #{description(resource).downcase} that has ever been published."
      return
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

    def setup_view_paths
      setup_view_paths_for(resource)
    end
end
