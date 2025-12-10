module FooterHelper
  def footer_items(is_editor: false)
    footer_items = []
    if Flipflop.enabled?(:design_system_edit_phase_3b)
      footer_items <<
        {
          title: "Reports, downtime and users",
          items: first_section(is_editor),
        }
      footer_items <<
        {
          title: "Support and feedback",
          columns: 2,
          items: second_section,
        }
    else
      footer_items << old_footer_items
    end
  end

  def first_section(is_editor)
    items = [
      {
        href: reports_path, text: "CSV reports"
      },
    ]
    if is_editor
      items << {
        href: downtimes_path,
        text: "Downtime messages",
      }
    end
    items << {
      href: user_search_path,
      text: "Search users",
    }
  end

  def second_section
    [
      {
        href: Plek.external_url_for("support"),
        text: "Raise a support request",
      },
      {
        href: "https://status.publishing.service.gov.uk/",
        text: "Check if publishing apps are working or if there’s any maintenance planned",
      },
      {
        href: "https://www.gov.uk/government/content-publishing",
        text: "How to write, publish, and improve content",
      },
    ]
  end

  def old_footer_items
    {
      title: "Support and feedback",
      items: [
        {
          href: Plek.external_url_for("support"),
          text: "Raise a support request",
        },
        {
          href: "https://status.publishing.service.gov.uk/",
          text: "Check if publishing apps are working or if there’s any maintenance planned",
        },
      ],
    }
  end
end
