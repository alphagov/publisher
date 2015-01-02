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

      def path(edition_path)
        name == 'edit' ? edition_path : "#{edition_path}/#{name}"
      end

      def link(edition_path)
        "<a href=\"#{path(edition_path)}\" data-target=\"##{name}\" data-toggle=\"tab\" role=\"tab\" aria-controls=\"#{name}\">#{title}</a>".html_safe
      end

      def active?(active)
        name == active.name
      end
    end
  end
end
