class MaintenanceMode
  def initialize(app)
    @app = app
  end

  def call(env)
    if maintenance_enabled?
      return [503, { "Content-Type" => "text/html" }, [maintenance_page]]
    end

    @app.call(env)
  end

private

  def maintenance_enabled?
    value = ENV["MAINTENANCE_MODE"]
    value == "true"
  end

  def maintenance_page
    ApplicationController.render(template: "maintenance/index", layout: false)
  end
end
