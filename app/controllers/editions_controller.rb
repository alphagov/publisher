require "statsd"
require "edition_duplicator"
require "edition_progressor"

class EditionsController < InheritedResources::Base
  actions :create, :update, :destroy
  defaults :resource_class => Edition, :collection_name => 'editions', :instance_name => 'resource'
  before_filter :setup_view_paths, :except => [:index, :new, :create]

  def index
    redirect_to root_path
  end

  def show
    if @resource.is_a?(Parted)
      @ordered_parts = @resource.parts.in_order
    end
    render
  end

  # TODO: Clean this up via better use of instance var names here and in publications_controller.rb
  def new
    @publication = build_resource
    setup_view_paths_for(@publication)
  end

  def create
    class_identifier = params[:edition].delete(:kind).to_sym
    statsd.increment("publisher.edition.create.#{class_identifier}")
    @publication = current_user.create_edition(class_identifier, params[:edition])

    if @publication.persisted?
      redirect_to edition_path(@publication),
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
      return_to = params[:return_to] || edition_path(command.new_edition)
      redirect_to return_to, :notice => 'New edition created'
    else
      redirect_to edition_path(resource), :alert => command.error_message
    end
  end

  def update
    # We have to call this before updating as it removes any assigned_to_id
    # parameter from the request, preventing us from inadvertently changing
    # it at the wrong time.
    assign_to = new_assignee

    update! do |success, failure|
      success.html {
        update_assignment resource, assign_to
        return_to = params[:return_to] || edition_path(resource)
        redirect_to return_to
      }
      failure.html {
        @resource = resource
        flash.now[:alert] = format_failure_message(resource)
        render :template => "show"
      }
      success.json {
        update_assignment resource, assign_to
        render :json => resource
      }
      failure.json { render :json => resource.errors, :status=>406 }
    end
  end

  def destroy
    if resource.can_destroy?
      destroy! do
        redirect_to root_url, :notice => "#{description(resource)} destroyed"
        return
      end
    else
      redirect_to edition_path(resource),
        :notice => "Cannot delete a #{description(resource).downcase} that has ever been published."
      return
    end
  end

  def progress
    command = EditionProgressor.new(resource, current_user, statsd)
    if command.progress(squash_multiparameter_datetime_attributes(params[:activity]))
      redirect_to edition_path(resource), notice: command.status_message
    else
      redirect_to edition_path(resource), alert: command.status_message
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

  private
    def squash_multiparameter_datetime_attributes(params)
      datetime_params = params.select { |k, v| k.include? 'publish_at' }.values.map(&:to_i)
      params.delete_if { |k, v| k.include? 'publish_at' }

      params['publish_at'] = DateTime.new(*datetime_params) if datetime_params.present?
      params
    end

    def format_failure_message(resource)
      resource_base_errors = resource.errors[:base]
      return resource.errors[:base].join('<br />') if resource_base_errors.present?
      "We had some problems saving. Please check the form below."
    end
end
