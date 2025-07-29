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
      # File.exist?(Rails.root.join("tmp", "maintenance.txt"))
      # true
      # ENV['MAINTENANCE_MODE'] == 'true'
      value = ENV["MAINTENANCE_MODE"]
  Rails.logger.info "ENV['MAINTENANCE_MODE'] = #{value.inspect}"
  value == "true"
    end
  
    def maintenance_page
      ApplicationController.render(template: "maintenance/index", layout: false)
    end
end
