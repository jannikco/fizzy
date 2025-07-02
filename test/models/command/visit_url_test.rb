require "test_helper"

class Command::VisitUrlTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:david)
    @card = cards(:logo)
    @script_name = integration_session.default_url_options[:script_name]
  end

  test "visit a path without the account slug" do
    result = visit_command("/foo/1234/bar").execute

    assert_kind_of Command::Result::Redirection, result
    assert_equal "#{@script_name}/foo/1234/bar", result.url
  end

  test "visit a path with the account slug" do
    result = visit_command("#{@script_name}/foo/1234/bar").execute

    assert_kind_of Command::Result::Redirection, result
    assert_equal "#{@script_name}/foo/1234/bar", result.url
  end

  test "visit an object path" do
    result = visit_command(@card).execute

    assert_kind_of Command::Result::Redirection, result
    assert_equal @card, result.url
  end

  private
    def visit_command(url)
      context = Command::Parser::Context.new(@user, url: collection_card_url(@card.collection, @card), script_name: integration_session.default_url_options[:script_name])
      Command::VisitUrl.new(url: url, context: context)
    end
end
