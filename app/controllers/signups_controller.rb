class SignupsController < ApplicationController
  # FIXME: Remove this before launch!
  unless Rails.env.local?
    http_basic_authenticate_with \
      name: Rails.application.credentials.account_signup_http_basic_auth.name,
      password: Rails.application.credentials.account_signup_http_basic_auth.password,
      realm: "Fizzy Signup"
  end

  disallow_account_scope
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_signup_path, alert: "Try again later." }
  before_action :redirect_authenticated_user

  layout "public"

  def new
    @signup = Signup.new
  end

  def create
    Signup.new(signup_params).create_identity
    redirect_to session_magic_link_path
  end

  private
    def redirect_authenticated_user
      redirect_to new_signup_completion_path if authenticated?
    end

    def signup_params
      params.expect signup: :email_address
    end
end
