require 'sinatra'
require 'erubis'

class GuidesFrontEnd < Sinatra::Base
  set :views, File.expand_path('../app/views/guides_front_end', __FILE__)

  def self.preview_mode?(env)
    env.has_key?('action_dispatch.request.path_parameters')
  end

  def preview_mode?
    self.class.preview_mode?(request.env)
  end

  def self.preview_edition_id(env)
    env['action_dispatch.request.path_parameters'][:edition_id]
  end

  def preview_edition_id
    self.class.preview_edition_id(request.env)
  end

  get '/:slug' do
    guide = Guide.where(:slug => params[:slug]).first
    halt(404) if guide.nil? # 404 if guide not found
    edition = preview_mode? ? guide.editions.first {|s| s.version_number == preview_edition_id.to_i } : guide.published_edition
    halt(404) if edition.nil? # 404 if edition not found
    erubis :guide, :edition => edition
  end
end