module Attachable
  class ApiClientNotPresent < StandardError; end

  def self.asset_api_client
    @asset_api_client
  end

  def self.asset_api_client=(api_client)
    @asset_api_client = api_client
  end

  module ClassMethods
    def attaches(*fields)
      options = if fields.last.is_a?(Hash)
                  fields.pop
                else
                  {}
                end
      attaches_with_options(fields, options)
    end

  private

    def attaches_with_options(fields, options = {})
      fields.map(&:to_s).each do |field|
        before_save "upload_#{field}".to_sym, if: "#{field}_has_changed?".to_sym
        self.field "#{field}_id".to_sym, type: String
        if options[:with_url_field]
          self.field "#{field}_url".to_sym, type: String
        end

        define_method(field) do
          raise ApiClientNotPresent unless Attachable.asset_api_client
          unless self.send("#{field}_id").nil?
            @attachments ||= {}
            @attachments[field] ||= Attachable.asset_api_client.asset(self.send("#{field}_id"))
          end
        end

        define_method("#{field}=") do |file|
          instance_variable_set("@#{field}_has_changed", true)
          instance_variable_set("@#{field}_file", file)
        end

        define_method("#{field}_has_changed?") do
          instance_variable_get("@#{field}_has_changed")
        end

        define_method("remove_#{field}=") do |value|
          unless value.nil? || value == false || (value.respond_to?(:empty?) && value.empty?)
            self.send("#{field}_id=", nil)
          end
        end

        define_method("upload_#{field}") do
          raise ApiClientNotPresent unless Attachable.asset_api_client
          begin
            if options[:update_existing] && !self.send("#{field}_id").nil?
              response = Attachable.asset_api_client.update_asset(self.send("#{field}_id"), file: instance_variable_get("@#{field}_file"))
            else
              response = Attachable.asset_api_client.create_asset(file: instance_variable_get("@#{field}_file"))
              self.send("#{field}_id=", response["id"].split('/').last)
            end

            self.send("#{field}_url=", response["file_url"]) if self.respond_to?("#{field}_url=")
          rescue StandardError
            errors.add("#{field}_id".to_sym, "could not be uploaded")
          end
        end
        private "upload_#{field}".to_sym
      end
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end
end
