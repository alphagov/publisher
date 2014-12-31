module View
  module Edition
    class Tab < Struct.new(:name)

      TABS = ['edit', 'metadata', 'history', 'admin']

      def self.all
        TABS.map {|name| Tab.new(name)}
      end

      def self.[](name)
        Tab.new(name)
      end

      def title
        name == 'history' ? 'History and notes' : name.capitalize
      end

      def path(edition)
        path = Rails.application.routes.url_helpers.edition_path(edition)
        name == 'edit' ? path : "#{path}/#{name}"
      end

      def partial
        "/shared/#{name}"
      end

      def link(edition)
        "<a href=\"#{path(edition)}\" data-target=\"##{name}\" data-toggle=\"tab\" role=\"tab\" aria-controls=\"#{name}\">#{title}</a>".html_safe
      end

      def active?(active)
        name == active.name
      end
    end
  end
end
