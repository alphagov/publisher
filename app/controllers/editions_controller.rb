require "edition_duplicator"
require "edition_progressor"

class EditionsController < InheritedResources::Base
  actions :create, :update, :destroy
  defaults :resource_class => Edition, :collection_name => 'editions', :instance_name => 'resource'
  before_filter :setup_view_paths, :except => [:index, :new, :create]
  after_filter :report_state_counts, :only => [:create, :duplicate, :progress, :destroy]
  before_filter :remove_blank_collections, only: [:create, :update]

  def index
    redirect_to root_path
  end

  def show
    if @resource.is_a?(Parted)
      @ordered_parts = @resource.parts.in_order
    end
    render :action => "show"
  end
  alias_method :metadata, :show
  alias_method :history, :show
  alias_method :admin, :show

  # TODO: Clean this up via better use of instance var names here and in publications_controller.rb
  def new
    @publication = build_resource
    setup_view_paths_for(@publication)
  end

  def create
    class_identifier = params[:edition].delete(:kind).to_sym
    create_params = permitted_params(subtype: :"#{class_identifier}_edition")
    @publication = current_user.create_edition(class_identifier, create_params[:edition])

    if @publication.persisted?
      flash[:success] = "#{description(@publication)} successfully created"
      redirect_to edition_path(@publication)
      return
    else
      setup_view_paths_for(@publication)
      render :action => "new"
    end
  end

  def duplicate
    command = EditionDuplicator.new(resource, current_user)
    target_edition_class_name = (params[:to] + "_edition").classify if params[:to]

    if !resource.can_create_new_edition?
      flash[:warning] = 'Another person has created a newer edition'
      redirect_to edition_path(resource)
    elsif command.duplicate(target_edition_class_name, new_assignee)
      return_to = params[:return_to] || edition_path(command.new_edition)
      flash[:success] = 'New edition created'
      redirect_to return_to
    else
      flash[:danger] = command.error_message
      redirect_to edition_path(resource)
    end
  end

  def update
    # We have to call this before updating as it removes any assigned_to_id
    # parameter from the request, preventing us from inadvertently changing
    # it at the wrong time.
    assign_to = new_assignee

    attempted_activity = Edition::ACTIONS.invert[params[:commit]]
    activity_params = attempted_activity_params(attempted_activity)
    remove_activity_params
    coerce_business_support_params

    # update! is from the Inherited Resources gem
    # https://github.com/josevalim/inherited_resources/blob/master/lib/inherited_resources/actions.rb#L42
    update! do |success, failure|
      success.html {
        progress_edition(resource, activity_params) if attempted_activity
        update_assignment resource, assign_to
        return_to = params[:return_to] || edition_path(resource)
        redirect_to return_to
      }
      failure.html {
        @resource = resource
        flash.now[:danger] = format_failure_message(resource)
        render :action => "show"
      }
      success.json {
        progress_edition(resource, activity_params) if attempted_activity
        update_assignment resource, assign_to
        render :json => resource
      }
      failure.json { render :json => resource.errors, :status=>406 }
    end
  end

  def review
    if resource.reviewer.present?
      flash[:danger] = "#{resource.reviewer} has already claimed this 2i"
      redirect_to edition_path(resource)
      return
    end

    resource.reviewer = params[:edition][:reviewer]
    if resource.save!
      flash[:success] = "You are the reviewer of this #{description(resource).downcase}."
    else
      flash[:danger] = "Something went wrong when attempting to claim 2i."
    end
    redirect_to edition_path(resource)
  end

  def destroy
    if resource.can_destroy?
      destroy! do
        flash[:success] = "#{description(resource)} destroyed"
        redirect_to root_url
        return
      end
    else
      flash[:danger] = "Cannot delete a #{description(resource).downcase} that has ever been published."
      redirect_to edition_path(resource)
      return
    end
  end

  def progress
    if progress_edition(resource, params[:edition][:activity].permit(:comment, :request_type, :publish_at))
      flash[:success] = @command.status_message
    else
      flash[:danger] = @command.status_message
    end
    redirect_to edition_path(resource)
  end

  def diff
    @resource = resource
    @comparison = @resource.previous_siblings.last
  end

protected

  def permitted_params(subtype: nil)
    subtype = @resource.class.to_s.underscore.to_sym if subtype.nil?
    params.permit(edition: type_specific_params(subtype) + common_params)
  end

  def type_specific_params(subtype)
    case subtype
    when :business_support_edition
      [
        :organiser,
        :short_description,
        :body,
        :eligibility,
        :evaluation,
        :additional_information,
        :contact_details,
        :max_employees,
        :min_value,
        :max_value,
        :will_continue_on,
        :continuation_link,
        :priority,
        :start_date,
        :end_date,
        area_gss_codes: [],
        business_types: [],
        business_sizes: [],
        locations: [],
        purposes: [],
        sectors: [],
        stages: [],
        support_types: [],
      ]
    when :campaign_edition
      [
        :small_image,
        :medium_image,
        :large_image,
        :organisation_formatted_name,
        :organisation_url,
        :organisation_crest,
        :organisation_brand_colour,
        :body,
      ]
    when :guide_edition, :programme_edition
      [
        parts_attributes: [:title, :body, :slug, :order, :id, :_destroy]
      ]
    when :licence_edition
      [
        :licence_identifier,
        :will_continue_on,
        :continuation_link,
        :licence_short_description,
        :licence_overview,
      ]
    when :local_transaction_edition
      [
        :lgsl_code,
        :lgil_override,
        :introduction,
        :more_information,
        :need_to_know,
      ]
    when :place_edition
      [
        :place_type,
        :introduction,
        :more_information,
        :need_to_know,
      ]
    when :simple_smart_answer_edition
      [
        :body,
        nodes_attributes: [
          :slug, :title, :body, :order, :kind, :id, :_destroy,
          options_attributes: [:label, :next_node, :id, :_destroy]
        ],
      ]
    when :transaction_edition
      [
        :introduction,
        :will_continue_on,
        :link,
        :more_information,
        :alternate_methods,
        :need_to_know,
        :department_analytics_profile,
      ]
    when :video_edition
      [
        :body,
        :video_url,
        :video_summary,
        :caption_file,
      ]
    else # answer_edition, completed_transaction_edition, help_page_edition
      [
        :body,
      ]
    end
  end

  def common_params
    [
      :assigned_to_id,
      :reviewer,
      :panopticon_id,
      :slug,
      :change_note,
      :major_change,
      :title,
      :in_beta,
      :overview,
      :primary_topic,
      browse_pages: [],
      additional_topics: [],
    ]
  end

  def new_assignee
    assignee_id = (params[:edition] || {}).delete(:assigned_to_id)
    User.find(assignee_id) if assignee_id.present?
  end

  def update_assignment(edition, assignee)
    return if edition.assigned_to == assignee
    if assignee
      current_user.assign(edition, assignee)
    else
      current_user.unassign(edition)
    end
  end

  def setup_view_paths
    setup_view_paths_for(resource)
  end

  def description(r)
    r.format.underscore.humanize
  end

private

  def attempted_activity_params(attempted_activity)
    return unless attempted_activity
    params[:edition]["activity_#{attempted_activity}_attributes"].permit(
      :request_type, :email_addresses, :customised_message, :comment, :publish_at)
  end

  def remove_activity_params
    params[:edition].delete_if { |attributes, _| attributes =~ /\Aactivity_\w*_attributes\z/ }
  end

  def remove_blank_collections
    [:primary_topic].each do |collection_name|
      params[:edition][collection_name] = nil if params[:edition][collection_name].blank?
    end

    [:browse_pages, :additional_topics].each do |collection_name|
      if params[:edition].has_key?(collection_name)
        params[:edition][collection_name] = params[:edition][collection_name].reject(&:blank?)
      end
    end
  end

  def format_failure_message(resource)
    resource_base_errors = resource.errors[:base]
    return resource.errors[:base].join('<br />') if resource_base_errors.present?
    "We had some problems saving. Please check the form below."
  end

  def progress_edition(resource, activity_params)
    @command = EditionProgressor.new(resource, current_user)
    @command.progress(squash_multiparameter_datetime_attributes(activity_params, ['publish_at']))
  end

  def report_state_counts
    Publisher::Application.edition_state_count_reporter.report
  end

  def coerce_business_support_params
    if params[:edition][:area_gss_codes]
      params[:edition][:area_gss_codes] = params[:edition][:area_gss_codes].reject(&:empty?)
    end
  end
end
