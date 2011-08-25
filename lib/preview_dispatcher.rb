require 'local_transactions_front_end'
require 'places_front_end'
require 'guides_front_end'
require 'programmes_front_end'

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
        return dispatcher_map[publication.class.name].call(env)
      end
    end
  end
end
