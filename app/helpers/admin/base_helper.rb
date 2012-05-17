module Admin::BaseHelper

  def publication_tab_list(*statuses)
    # Allow passing :current => 'something' as the last argument
    if statuses[-1].is_a? Hash
      options = statuses.pop
    else
      options = {}
    end

    output = statuses.collect do |status|
      scope = status.downcase.gsub(' ', '_')
      li_classes = ['status-option']
      li_classes << 'active' if scope == options[:current]

      content_tag(:li, class: li_classes.join(' ')) do
        url = admin_root_path(:filter => params[:filter], :title => params[:title], :list => scope)

        content_tag(:a, :href => url) do
          h(status + " ") + content_tag(:span, @presenter.send(scope).length, class: "label pull-right")
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
