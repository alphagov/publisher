require "edition_duplicator"
require "edition_progressor"

class EditionsController < InheritedResources::Base
  actions :create, :update, :destroy

  defaults resource_class: Edition, collection_name: 'editions', instance_name: 'resource'
  before_action :setup_view_paths, except: [:index, :new, :create]
  after_action :report_state_counts, only: [:create, :duplicate, :progress, :destroy]

  def index
    redirect_to root_path
  end

  def show
    @linkables = Tagging::Linkables.new

    if @resource.is_a?(Parted)
      @ordered_parts = @resource.parts.in_order
    end

    @tagging_update = tagging_update_form
    @artefact = @resource.artefact

    render action: "show"
  end
  alias_method :metadata, :show
  alias_method :history, :show
  alias_method :admin, :show
  alias_method :unpublish, :show

  def new
    @publication = build_resource
    setup_view_paths_for(@publication)
  end

  def create
    class_identifier = params[:edition].delete(:kind).to_sym
    create_params = permitted_params(subtype: :"#{class_identifier}_edition")
    @publication = current_user.create_edition(class_identifier, create_params[:edition])

    if @publication.persisted?
      UpdateWorker.perform_async(@publication.id.to_s)

      flash[:success] = "#{description(@publication)} successfully created"
      redirect_to edition_path(@publication)
      return
    else
      setup_view_paths_for(@publication)
      render action: "new"
    end
  end

  def duplicate
    command = EditionDuplicator.new(resource, current_user)
    target_edition_class_name = (params[:to] + "_edition").classify if params[:to]

    if !resource.can_create_new_edition?
      flash[:warning] = 'Another person has created a newer edition'
      redirect_to edition_path(resource)
    elsif command.duplicate(target_edition_class_name, new_assignee)
      new_edition = command.new_edition
      UpdateWorker.perform_async(new_edition.id.to_s)

      return_to = params[:return_to] || edition_path(new_edition)
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

    activity_params = attempted_activity_params
    remove_activity_params

    # update! is from the Inherited Resources gem
    # https://github.com/josevalim/inherited_resources/blob/master/lib/inherited_resources/actions.rb#L42
    update! do |success, failure|
      success.html {
        progress_edition(resource, activity_params) if attempted_activity

        update_assignment resource, assign_to

        UpdateWorker.perform_async(resource.id.to_s)
        PublishWorker.perform_async(resource.id.to_s) if update_action_is_publish?

        return_to = params[:return_to] || edition_path(resource)
        redirect_to return_to
      }
      failure.html {
        @resource = resource
        @tagging_update = tagging_update_form
        @linkables = Tagging::Linkables.new
        @artefact = @resource.artefact
        flash.now[:danger] = format_failure_message(resource)
        render action: "show"
      }
      success.json {
        progress_edition(resource, activity_params) if attempted_activity

        update_assignment resource, assign_to

        UpdateWorker.perform_async(resource.id.to_s)
        PublishWorker.perform_async(resource.id.to_s) if update_action_is_publish?

        render json: resource
      }
      failure.json { render json: resource.errors, status: 406 }
    end
  end

  def linking
    @linkables = Tagging::Linkables.new
    @tagging_update = tagging_update_form
    @artefact = @resource.artefact
    render action: "show"
  end

  def update_tagging
    Tagging::TaggingUpdateForm.new(params[:tagging_tagging_update_form]).publish!
    redirect_to :back, flash: { success: "Tags have been updated!" }
  rescue GdsApi::HTTPConflict
    redirect_to :back,
    flash: {
      danger: "Somebody changed the tags before you could. Your changes have not been saved."
    }
  end

  def update_related_external_links
    artefact = resource.artefact

    if params.has_key?("artefact")
      external_links = params.require(:artefact).permit(external_links_attributes: [:title, :url, :id, :_destroy])
      artefact.external_links_attributes = external_links["external_links_attributes"]

      if artefact.save
        flash[:success] = "External links have been saved. They will be visible the next time this publication is published."
      else
        flash[:danger] = artefact.errors.full_messages.join("\n")
      end
    else
      flash[:danger] = "There aren't any external related links yet"
    end

    redirect_to :back
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
      PublishWorker.perform_async(resource.id.to_s) if progress_action_is_publish?

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

  def process_unpublish
    edition = Edition.find(params[:id])
    artefact = edition.artefact
    success = UnpublishService.call(artefact, current_user, redirect_url)

    if success
      notice = "Content unpublished"
      notice << " and redirected" if redirect_url.present?
      flash[:notice] = notice
      redirect_to root_path
    else
      flash[:alert] = artefact.errors.full_messages.join("\n")
      redirect_to unpublish_edition_path(edition)
    end
  end

protected

  def permitted_params(subtype: nil)
    subtype = @resource.class.to_s.underscore.to_sym if subtype.nil?
    params.permit(edition: type_specific_params(subtype) + common_params)
  end

  def type_specific_params(subtype)
    case subtype
    when :guide_edition
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
        :lgil_code,
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
        :start_button_text,
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
    when :completed_transaction_edition
      [
        :body,
        :promotion_choice,
        :promotion_choice_url,
      ]
    else # answer_edition, help_page_edition
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

  def redirect_url
    make_govuk_url_relative params["redirect_url"]
  end

  def make_govuk_url_relative(url = "")
    url.sub(%r{^https?://(www\.)?gov\.uk/}, "/")
  end

  def tagging_update_form
    Tagging::TaggingUpdateForm.build_from_publishing_api(@resource.artefact.content_id)
  end

  def attempted_activity_params
    return unless attempted_activity
    params[:edition]["activity_#{attempted_activity}_attributes"].permit(
      :request_type, :email_addresses, :customised_message, :comment, :publish_at)
  end

  def remove_activity_params
    params[:edition].delete_if { |attributes, _| attributes =~ /\Aactivity_\w*_attributes\z/ }
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

  def update_action_is_publish?
    attempted_activity == :publish
  end

  def progress_action_is_publish?
    progress_action_param == "publish"
  end

  def progress_action_param
    params[:edition][:activity][:request_type]
  rescue
    nil
  end

  def attempted_activity
    Edition::ACTIONS.invert[params[:commit]]
  end
end
