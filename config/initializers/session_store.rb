# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store,
                                       key: '_publisher_session',
                                       secure: Rails.env.production? && !ENV['DISABLE_SECURE_COOKIES'],
                                       http_only: true
