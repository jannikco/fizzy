require "test_helper"

class Signup::AccountsControllerTest < ActionDispatch::IntegrationTest
  test "new under a tenanted URL redirects to the root" do
    get new_signup_account_url

    assert_redirected_to root_url
  end

  test "new under an untenanted URL is OK" do
    integration_session.default_url_options[:script_name] = "" # no tenant

    get new_signup_account_url, headers: auth_headers

    assert_response :success
  end

  test "create with invalid params" do
    integration_session.default_url_options[:script_name] = "" # no tenant

    post signup_accounts_url,
         headers: auth_headers,
         params: { signup: { full_name: "Jim", email_address: "jim@example.com", password: "", company_name: "" } }

    assert_response :unprocessable_entity
    assert_select "div.alert--error", text: /you need to choose a password/i
  end

  test "create for a new " do
    integration_session.default_url_options[:script_name] = "" # no tenant

    assert_difference -> { SignalId::Identity.count }, +1 do
      assert_difference -> { SignalId::Account.count }, +1 do
        post signup_accounts_url, headers: auth_headers,
             params: {
               signup: {
                 full_name: "Jim",
                 email_address: "jim@example.com",
                 password: SecureRandom.hex(12),
                 company_name: "signup-accounts-controller-test-1"
               }
             }
      end
    end

    signal_account = SignalId::Account.last
    assert_redirected_to(/#{signal_account.login_url}/)
  end

  test "create for an existing identity" do
    integration_session.default_url_options[:script_name] = "" # no tenant

    identity = signal_identities(:david)

    post signup_accounts_url, headers: auth_headers,
         params: { signup: { email_address: identity.email_address, company_name: "signup-accounts-controller-test-2" } }

    assert_authentication_requested_for identity

    assert_no_difference -> { SignalId::Identity.count } do
      assert_difference -> { SignalId::Account.count } do
        authenticate_via_launchpad_as(identity)
        assert_redirected_to_account
        assert_nil session[:signup]
      end
    end

    signal_account = SignalId::Account.last
    ApplicationRecord.with_tenant(signal_account.subdomain) do
      assert_equal Account.last, signal_account.peer
    end
  end

  test "actions require HTTP basic authentication while we're in internal-only mode" do
    integration_session.default_url_options[:script_name] = "" # no tenant

    get new_signup_account_url

    assert_response :unauthorized
  end

  private
    def auth_headers
      { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("testname", "testpassword") }
    end

    def assert_authentication_requested_for(identity)
      assert_response :redirect
      assert_match(/#{Regexp.escape(Launchpad.url("/authenticate", login_hint: identity.email_address))}.*&purpose=signup/, redirect_to_url)
    end

    def authenticate_via_launchpad_as(identity)
      get signup_session_url, headers: auth_headers, params: { sig: identity.perishable_signature }
      assert_equal identity.id, session[:signup]["identity_id"]
      assert_redirected_to new_signup_completion_url
      post signup_completions_url, headers: auth_headers
    end

    def assert_redirected_to_account(signal_account = SignalId::Account.last)
      assert_response :redirect
      assert_match(/#{Regexp.escape(signal_account.url("/session/launchpad"))}.*&sig=/, redirect_to_url)
    end
end
