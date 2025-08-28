require_relative "production"

Rails.application.configure do
  config.action_mailer.smtp_settings[:domain] = config.hosts.first
  config.action_mailer.smtp_settings[:address] = "smtp-outbound-staging"
  config.action_mailer.default_url_options = { host: config.hosts.first, protocol: "https" }

  # Let's keep beta on local disk. See https://github.com/basecamp/fizzy/pull/557 for context.
  config.active_storage.service = :local
end
