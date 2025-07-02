class Command::Parser
  attr_reader :context

  delegate :user, :cards, :filter, :script_name, to: :context

  def initialize(context)
    @context = context
  end

  def parse(string)
    parse_command(string).tap do |command|
      command.user = user
      command.line ||= string
      command.context ||= context
      command.default_url_options[:script_name] = script_name
    end
  end

  private
    def parse_command(string)
      command_name, *command_arguments = string.strip.split(" ")
      combined_arguments = command_arguments.join(" ")

      case command_name
      when /^#/
        Command::FilterByTag.new(tag_title: tag_title_from(string), params: filter.as_params)
      when /^@/
        Command::GoToUser.new(user_id: assignee_from(command_name)&.id)
      when "/user"
        Command::GoToUser.new(user_id: assignee_from(combined_arguments)&.id)
      when "/assign", "/assignto"
        Command::Assign.new(assignee_ids: assignees_from(command_arguments).collect(&:id), card_ids: cards.ids)
      when "/clear"
        Command::ClearFilters.new(params: filter.as_params)
      when "/close"
        Command::Close.new(card_ids: cards.ids, reason: combined_arguments)
      when "/consider", "/reconsider"
        Command::Consider.new(card_ids: cards.ids)
      when "/do"
        Command::Do.new(card_ids: cards.ids)
      when "/insight"
        Command::GetInsight.new(query: combined_arguments, card_ids: cards.ids)
      when "/add_card"
        Command::AddCard.new(card_title: combined_arguments, collection_id: guess_collection&.id)
      when "/search"
        Command::Search.new(terms: combined_arguments)
      when "/stage"
        Command::Stage.new(stage_id: stage_from(combined_arguments)&.id, card_ids: cards.ids)
      when "/visit"
        Command::VisitUrl.new(url: command_arguments.first)
      when "/tag"
        Command::Tag.new(tag_title: tag_title_from(combined_arguments), card_ids: cards.ids)
      else
        parse_free_string(string)
      end
    end

  private
    def assignees_from(strings)
      Array(strings).filter_map do |string|
        assignee_from(string)
      end
    end

    # TODO: This is temporary as it can be ambiguous. We should inject the user ID in the command
    #   under the hood instead, as determined by the user picker. E.g: @1234.
    def assignee_from(string)
      string_without_at = string.delete_prefix("@")
      User.all.find { |user| user.mentionable_handles.include?(string_without_at.downcase) }
    end

    def stage_from(combined_arguments)
      candidate_stages.find do |stage|
        stage.name.downcase.include?(combined_arguments.downcase)
      end
    end

    def guess_collection
      cards.first&.collection || Collection.first
    end

    def candidate_stages
      Workflow::Stage.where(workflow_id: cards.joins(:collection).select("collections.workflow_id").distinct)
    end

    def tag_title_from(string)
      string.gsub(/^#/, "")
    end

    def parse_free_string(string)
      if cards = multiple_cards_from(string)
        Command::FilterCards.new(card_ids: cards.ids, params: filter.as_params)
      elsif card = single_card_from(string)
        Command::GoToCard.new(card_id: card.id)
      else
        Command::Ai::Parser.new(context).parse(string)
      end
    end

    def multiple_cards_from(string)
      if string.match?(/^[\d\s,]+$/)
        tokens = string.split(/[\s,]+/)
        user.accessible_cards.where(id: tokens).presence if tokens&.many?
      end
    end

    def single_card_from(string)
      user.accessible_cards.find_by_id(string)
    end
end
