Rails.application.config.before_initialize do
  # We don't want normal tenanted authentication on mission control.
  # Note that we're using HTTP basic auth configured via credentials.
  MissionControl::Jobs.base_controller_class = "ActionController::Base"
end
