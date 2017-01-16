module TabsHelper
  def active_tab
    return @active_tab if @active_tab

    visited_tab = request.path.split("/").last
    tab_name = [visited_tab] & %w(metadata tagging history admin related_external_links unpublish)
    @active_tab = tab_name.blank? ? Edition::Tab['edit'] : Edition::Tab[tab_name.first]
  end

  def tab_link(tab, edition_path)
    link_to tab.title, tab.path(edition_path),
      'data-target' => "##{tab.name}",
      'data-toggle' => 'tab',
      'role' => 'tab',
      'aria-controls' => tab.name
  end

  def tabs
    Edition::Tab.all
  end

  module Edition
    class Tab < Struct.new(:name)

      TABS = %w(edit tagging metadata history admin related_external_links unpublish)

      def self.all
        @@all ||= TABS.map { |name| Tab.new(name) }
      end

      def self.[](name)
        Tab.new(name)
      end

      def title
        case name
        when 'history'
          'History and notes'
        when 'related_external_links'
          'Related external links'
        else
          name.capitalize
        end
      end

      def path(edition_path)
        name == 'edit' ? edition_path : "#{edition_path}/#{name}"
      end

      def ==(other_tab)
        name == other_tab.name
      end
    end
  end
end
