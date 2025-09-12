require "ostruct"

class CardsController < ApplicationController
  include Collections::ColumnsScoped

  before_action :set_collection, only: %i[ create ]
  before_action :set_card, only: %i[ show edit update destroy ]

  enable_collection_filtering only: :index

  PAGE_SIZE = 25

  def index
    @considering = page_and_filter_for @filter.with(engagement_status: "considering"), per_page: PAGE_SIZE
    @on_deck = page_and_filter_for @filter.with(engagement_status: "on_deck"), per_page: PAGE_SIZE
    @doing = page_and_filter_for @filter.with(engagement_status: "doing"), per_page: PAGE_SIZE
    @closed = page_and_filter_for_closed_cards

    @cache_key = [ @considering, @on_deck, @doing, @closed ].collect { it.page.records }.including([ Workflow.all ])
    fresh_when etag: [ @cache_key, @user_filtering ]
  end

  def create
    card = @collection.cards.create!
    redirect_to card
  end

  def show
    fresh_when @card
  end

  def edit
  end

  def update
    @card.update! card_params

    if @card.published?
      render_card_replacement
    else
      redirect_to @card
    end
  end

  def destroy
    @card.destroy!
    redirect_to cards_path(collection_ids: [ @card.collection ]), notice: ("Card deleted" unless @card.creating?)
  end

  private
    def set_collection
      @collection = Current.user.collections.find(params[:collection_id])
    end

    def set_card
      @card = Current.user.accessible_cards.find params[:id]
    end

    def card_params
      params.expect(card: [ :status, :title, :description, :image, tag_ids: [] ])
    end

    def render_card_replacement
      render turbo_stream: turbo_stream.replace([ @card, :card_container ], partial: "cards/container", locals: { card: @card.reload })
    end
end
