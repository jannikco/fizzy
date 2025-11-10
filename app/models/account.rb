class Account < ApplicationRecord
  include Entropic, Seedeable

  has_one :join_code
  has_many :users, dependent: :destroy

  has_many_attached :uploads

  after_create :create_join_code

  validates :name, presence: true

  class << self
    def create_with_admin_user(account:, owner:)
      create!(**account).tap do |account|
        User.create!(account: account, role: :system, name: "System")
        User.create!(**owner.reverse_merge(role: "admin", account: account))
      end
    end
  end

  # To use the account as a generic card container. See +Entropy+.
  def cards
    Card.all
  end

  def slug
    "/#{external_account_id}"
  end
end
