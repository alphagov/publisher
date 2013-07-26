require "statsd"
require "edition_duplicator"
require "edition_progressor"

class Admin::EditionsController < Admin::BaseController
  actions :create, :update, :destroy
  defaults :resource_class => Edition, :collection_name => 'editions', :instance_name => 'resource'
  before_filter :setup_view_paths, :except => [:index, :new, :create]

  def index
    redirect_to admin_root_path
  end

  def show
    if @resource.is_a?(Parted)
      @ordered_parts = @resource.parts.in_order
    end
    render
  end

  # TODO: Clean this up via better use of instance var names here and in admin/publications_controller.rb
  def new
    @publication = build_resource
    setup_view_paths_for(@publication)
  end

  def create
    class_identifier = params[:edition].delete(:kind).to_sym
    statsd.increment("publisher.edition.create.#{class_identifier}")
    @publication = current_user.create_edition(class_identifier, params[:edition])

    if @publication.persisted?
      redirect_to admin_edition_path(@publication),
        :notice => "#{description(@publication)} successfully created"
      return
    else
      setup_view_paths_for(@publication)
      render :action => "new"
    end
  end

  def duplicate
    command = EditionDuplicator.new(resource, current_user)

    if command.duplicate(params[:to], new_assignee)
      return_to = params[:return_to] || admin_edition_path(command.new_edition)
      redirect_to return_to, :notice => 'New edition created'
    else
      redirect_to admin_edition_path(resource), :alert => command.error_message
    end
  end

  def update
    # We have to call this before updating as it removes any assigned_to_id
    # parameter from the request, preventing us from inadvertently changing
    # it at the wrong time.
    assign_to = new_assignee

    update! do |success, failure|
      success.html {
        # Automatically start work if we haven't already
        if resource.can_start_work?
          command = EditionProgressor.new(resource, current_user, statsd)
          command.progress(request_type: 'start_work')
        end
        # Assign to right person
        update_assignment resource, assign_to
        # Redirect
        return_to = params[:return_to] || admin_edition_path(resource)
        redirect_to return_to
      }
      failure.html {
        @resource = resource
        flash.now[:alert] = "We had some problems saving. Please check the form below."
        render :template => "show"
      }
      success.json {
        # Automatically start work if we haven't already
        if resource.can_start_work?
          command = EditionProgressor.new(resource, current_user, statsd)
          command.progress(request_type: 'start_work')
        end
        # Assign to right person
        update_assignment resource, assign_to
        # Result
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

  def progress
    command = EditionProgressor.new(resource, current_user, statsd)
    if command.progress(params[:activity])
      redirect_to admin_edition_path(resource), notice: command.status_message
    else
      redirect_to admin_edition_path(resource), alert: command.status_message
    end
  end

  protected
    def new_assignee
      assignee_id = (params[:edition] || {}).delete(:assigned_to_id)
      User.find(assignee_id) if assignee_id.present?
    end

    def update_assignment(edition, assignee)
      return if assignee.nil? || edition.assigned_to == assignee
      current_user.assign(edition, assignee)
    end

    def setup_view_paths
      setup_view_paths_for(resource)
    end

    def statsd
      @statsd ||= Statsd.new(::STATSD_HOST)
    end

    def description(r)
      r.format.underscore.humanize
    end
end
