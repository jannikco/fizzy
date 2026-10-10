# Send mail through the SMTP2GO HTTP API when SMTP2GO_API_KEY is set, for hosts
# where outbound SMTP ports are blocked. Takes precedence over the SMTP config
# in config/environments/production.rb. The delivery method lives in
# lib/rails_ext/smtp2go_delivery_method.rb (loaded via config/initializers/extensions.rb).
if ENV["SMTP2GO_API_KEY"].present? && !Rails.env.local?
  require "rails_ext/smtp2go_delivery_method"

  ActionMailer::Base.add_delivery_method :smtp2go, Smtp2goDeliveryMethod, api_key: ENV["SMTP2GO_API_KEY"]
  ActionMailer::Base.delivery_method = :smtp2go
end
