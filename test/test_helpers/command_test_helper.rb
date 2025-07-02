module CommandTestHelper
  def execute_command(string, context_url: nil, user: users(:david))
    parse_command(string, context_url: context_url, user: user).execute
  end

  def parse_command(string, context_url: nil, user: users(:david))
    context = Command::Parser::Context.new(user, url: context_url, script_name: integration_session.default_url_options[:script_name])
    parser = Command::Parser.new(context)
    parser.parse(string).tap do |command|
      command.user = user if command
    end
  end
end
