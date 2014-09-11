module BaseHelper

  def publication_tab_list(options)
    state_names = {
      drafts: 'Drafts',
      in_review: 'In review',
      amends_needed: 'Amends needed',
      out_for_fact_check: 'Out for fact check',
      fact_check_received: 'Fact check received',
      ready: 'Ready',
      scheduled_for_publishing: 'Scheduled',
      published: 'Published',
      archived: 'Archived',
    }
    output = state_names.collect do |scope, status_label|
      li_classes = ['status-option', scope]
      li_classes << 'active' if scope == options[:current]

      content_tag(:li, class: li_classes.join(' ')) do
        url = root_path(:user_filter => params[:user_filter], :string_filter => params[:string_filter], :list => scope)

        content_tag(:a, :href => url) do
          h(status_label + " ") + content_tag(:span, @presenter.send(scope).length, class: "badge pull-right")
        end
      end
    end
    safe_join(output)
  end

  def resource_fields
    "/#{@resource.format.underscore.downcase.pluralize}/fields"
  end

  def skip_fact_check_for_edition(edition)
    send("skip_fact_check_edition_path", edition)
  end

  def edition_can_be_deleted?(edition)
    ! edition.published?
  end

  def friendly_date(date)
    if Time.zone.now - date < 2.days
      time_ago_in_words(date) + " ago."
    else
      date.strftime("%d/%m/%Y %R")
    end
  end

  include PathsHelper
  include EditionActivityHelper
end
