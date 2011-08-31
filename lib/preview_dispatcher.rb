require 'local_transactions_front_end'
require 'places_front_end'
require 'guides_front_end'
require 'programmes_front_end'
require 'front_end_environment'

class PreviewDispatcher
  attr_reader :dispatcher_map

  def initialize(app = nil)
    @dispatcher_map = {
      "Guide" => GuidesFrontEnd::Preview,
      "Programme" => ProgrammesFrontEnd::Preview,
      "Transaction" => GuidesFrontEnd::Preview,
      "Answer" => GuidesFrontEnd::Preview,
      "Place" => PlacesFrontEnd::Preview,
      "LocalTransaction" => LocalTransactionsFrontEnd::Preview
    }
  end

  def call(env)
    segments = env['PATH_INFO'].split('/')
    while slug = segments.shift
      unless slug.empty?
        publication = Publication.where(slug: slug).first
        if publication
          return dispatcher_map[publication.class.name].call(env)
        else
          return [404, {'Content-Type' => 'text/html'}, 'Page not found']
        end  
      end
    end
  end
end
