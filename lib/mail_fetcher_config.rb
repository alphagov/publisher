class MailFetcherConfig
  def initialize(config_hash)
    non_symbol_keys = config_hash.keys.reject { |key| key.is_a? Symbol }
    unless non_symbol_keys.empty?
      keys_string = non_symbol_keys.map(&:inspect).join(", ")
      raise ArgumentError, "Non-symbolic keys: #{keys_string}"
    end

    @imap_details = if ENV["RUN_FACT_CHECK_FETCHER"] && config_hash.present?
                      config_hash.dup
                    end
  end

  def configure(mail_module = Mail)
    if @imap_details
      # We need to bind this to a local variable, because `Mail.defaults` calls
      # `instance_eval`, which will run in the context of a configuration
      # object within `Mail`
      imap_details = @imap_details

      mail_module.defaults do
        retriever_method :imap, imap_details
      end
      true
    else
      false
    end
  end
end
