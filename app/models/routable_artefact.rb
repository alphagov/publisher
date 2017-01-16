require 'plek'
require 'gds_api/router'

class RoutableArtefact
  attr_reader :artefact

  def initialize(artefact)
    @artefact = artefact
  end

  def logger
    Rails.logger
  end

  def router_api
    @router_api ||= GdsApi::Router.new(Plek.current.find('router-api'))
  end

  def submit(options = {})
    if artefact.live?
      register
    elsif artefact.archived? && artefact.redirect_url.present?
      redirect(artefact.redirect_url)
    elsif artefact.archived?
      delete
    else
      return
    end

    if options[:skip_commit] || prefixes.empty? && paths.empty?
      return
    end

    commit
  end

  def register
    prefixes.each do |path|
      logger.debug("Registering route #{path} (prefix) => #{rendering_app}")
      router_api.add_route(path, "prefix", rendering_app)
    end
    paths.each do |path|
      logger.debug("Registering route #{path} (exact) => #{rendering_app}")
      router_api.add_route(path, "exact", rendering_app)
    end
  end

  def delete
    prefixes.each do |path|
      logger.debug "Removing route #{path}"
      router_api.add_gone_route(path, "prefix")
    end
    paths.each do |path|
      logger.debug "Removing route #{path}"
      router_api.add_gone_route(path, "exact")
    end
  end

  def redirect(destination)
    prefixes.each do |path|
      logger.debug "Redirecting route #{path}"
      router_api.add_redirect_route(path, "prefix", destination, "permanent", segments_mode: "ignore")
    end
    paths.each do |path|
      logger.debug "Redirecting route #{path}"
      router_api.add_redirect_route(path, "exact", destination)
    end
  end

  def commit
    router_api.commit_routes
  end

private

  def rendering_app
    @rendering_app ||= [artefact.rendering_app, artefact.owning_app].reject(&:blank?).first
  end

  def paths
    artefact.paths || []
  end

  def prefixes
    artefact.prefixes || []
  end
end
