class Command::Parser::Context
  attr_reader :user, :url, :script_name

  def initialize(user, url:, script_name: "")
    @user = user
    @url = url
    @script_name = script_name

    extract_url_components
  end

  def cards
    if viewing_card_contents?
      user.accessible_cards.where id: params[:id]
    elsif viewing_cards_index?
      filter.cards.published
    elsif viewing_search_results?
      user.accessible_cards.where(id: user.search(params[:q]).select(:card_id))
    else
      Card.none
    end
  end

  def viewing_card_contents?
    viewing_card_perma?
  end

  def viewing_list_of_cards?
    viewing_cards_index? || viewing_search_results?
  end

  private
    attr_reader :controller, :action, :params

    MAX_CARDS = 20
    MAX_CLOSED_CARDS = 10

    def filter
      user.filters.from_params(params.permit(*Filter::Params::PERMITTED_PARAMS).reverse_merge(**FilterScoped::DEFAULT_PARAMS))
    end

    def viewing_card_perma?
      controller == "cards" && action == "show"
    end

    def viewing_cards_index?
      controller == "cards" && action == "index"
    end

    def viewing_search_results?
      controller == "searches" && action == "show"
    end

    def extract_url_components
      uri = URI.parse(url || "")
      path = uri.path.delete_prefix(script_name)
      route = Rails.application.routes.recognize_path(path)
      @controller = route[:controller]
      @action = route[:action]
      @params =  ActionController::Parameters.new(Rack::Utils.parse_nested_query(uri.query).merge(route.except(:controller, :action)))
    end
end
