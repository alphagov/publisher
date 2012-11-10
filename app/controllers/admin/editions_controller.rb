require "statsd"

class Admin::EditionsController < Admin::BaseController
  actions :create, :update, :destroy
  defaults :resource_class => Edition, :collection_name => 'editions', :instance_name => 'resource'
  before_filter :setup_view_paths, :except => [:index, :new, :create]

  def index
    redirect_to admin_root_path
  end

  # TODO: Clean this up via better use of instance var names here and in admin/publications_controller.rb
  def new
    @publication = build_resource
    setup_view_paths_for(@publication)
  end

  def create
    class_identifier = params[:edition].delete(:kind).to_sym
    Statsd.new(::STATSD_HOST).increment("publisher.edition.create.#{class_identifier}")
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
    new_edition = current_user.new_version(resource, (params[:to] || nil))
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

  def progress
    redirect_to admin_edition_path(resource), progress_message
  end

  protected
    def valid_fact_check_email_addresses?
      fact_check_request? and valid_email_addresses?
    end

    def fact_check_request?
      params[:activity][:request_type] == "send_fact_check"
    end

    def invalid_email_addresses?
      params[:activity][:email_addresses].split(",").any? do |address|
        !address.include?("@")
      end
    end

    def progress_message
      if invalid_fact_check_email_addresses?
        {
          alert:  "Couldn't #{params[:activity].to_s.humanize.downcase} for " +
                  "#{description(resource).downcase}. The email addresses " +
                  "you entered appear to be invalid."
        }
      elsif current_user.progress(resource, params[:activity].dup)
        collect_edition_status_stats
        { notice: success_message(params[:activity][:request_type]) }
      else
        { alert:  failure_message(params[:activity][:request_type]) }
      end
    end

    def collect_edition_status_stats
      intended_status = params[:activity][:request_type]
      statsd = Statsd.new(::STATSD_HOST)
      statsd.decrement("publisher.edition.#{resource.state}")
      statsd.increment("publisher.edition.#{intended_status}")
    end

    # TODO: This could probably live in the i18n layer?
    def failure_message(activity)
      case activity
      when 'skip_fact_check' then "Could not skip fact check for this publication."
      when 'start_work' then "Couldn't start work on #{description(resource).downcase}"
      else "Couldn't #{activity.to_s.humanize.downcase} for #{description(resource).downcase}"
      end
    end

    # TODO: This could probably live in the i18n layer?
    def success_message(activity)
      case activity
      when 'start_work' then "Work started on #{description(resource)}"
      when 'skip_fact_check' then "The fact check has been skipped for this publication."
      else "#{description(resource)} updated"
      end
    end

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
