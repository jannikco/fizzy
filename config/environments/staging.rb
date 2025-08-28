require_relative "production"

Rails.application.configure do
  config.action_mailer.smtp_settings[:domain] = config.hosts.first
  config.action_mailer.smtp_settings[:address] = "smtp-outbound-staging"
  config.action_mailer.default_url_options = { host: config.hosts.first, protocol: "https" }
end
