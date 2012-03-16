module Admin::BaseHelper

  def publication_tab_list(*statuses)
    output = statuses.collect do |status|
      content_tag(:li) do
        scope = status.downcase.gsub(' ', '_')
        url = admin_root_path(:filter => params[:filter], :list => scope)

        content_tag(:a, :href => url) do
          "#{status} (#{@presenter.send(scope).length})"
        end
      end
    end
    safe_join(output)
  end

  def resource_edit_view
    "/admin/#{@resource.format.underscore.downcase.pluralize}/edit"
  end

  def skip_fact_check_for_edition(edition)
    send("skip_fact_check_admin_edition_path", edition)
  end

  def edition_can_be_deleted?(edition)
    ! edition.published?
  end

  def produce_fact_check_request_text
    @edition = @resource
    render :partial => '/noisy_workflow/request_fact_check'
  end

  def friendly_date(date)
    if Time.now - date < 2.days
      time_ago_in_words(date) + " ago."
    else
      date.strftime("%d/%m/%Y %R")
    end
  end

  def govspeak_to_text(s)
    Govspeak::Document.new(s).to_text
  end

  include Admin::PathsHelper
  include Admin::ProgressFormsHelper
end
