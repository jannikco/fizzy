raise "Seeding is just for development" unless Rails.env.development?

require "active_support/testing/time_helpers"
include ActiveSupport::Testing::TimeHelpers

# Seed DSL
def seed_account(name)
  print "  #{name}…"
  elapsed = Benchmark.realtime { require_relative "seeds/#{name}" }
  puts " #{elapsed.round(2)} sec"
end

def create_tenant(signal_account_name)
  signal_account = SignalId::Account.find_by_product_and_name!("fizzy", signal_account_name)
  tenant_name = signal_account.queenbee_id

  ApplicationRecord.destroy_tenant tenant_name
  ApplicationRecord.create_tenant(tenant_name) do
    account = Account.create_with_admin_user(queenbee_id: signal_account.queenbee_id)
    account.setup_basic_template
  end

  ApplicationRecord.current_tenant = tenant_name
end

def find_or_create_user(full_name, email_address)
  SignalId::Database.on_master do
    unless signal_identity = SignalId::Identity.find_by_email_address(email_address)
      signal_identity = SignalId::Identity.create!(
        name: full_name,
        email_address: email_address,
        username: email_address,
        password: "secret123456"
      )
    end

    signal_account = Account.sole.signal_account
    signal_user = SignalId::User.find_or_create_by!(identity: signal_identity, account: signal_account)

    if user = User.find_by(signal_user_id: signal_user.id)
      user.password = "secret123456"
      user.save!
      user
    else
      User.create!(
        signal_user_id: signal_user.id,
        name: signal_identity.name,
        email_address: signal_identity.email_address,
        password: "secret123456"
      )
    end
  end
end

def login_as(user)
  Current.session = user.sessions.create
end

def create_collection(name, creator: Current.user, all_access: true, access_to: [])
  Collection.create!(name:, creator:, all_access:).tap { it.accesses.grant_to(access_to) }
end

def create_card(title, collection:, description: nil, status: :published, creator: Current.user)
  collection.cards.create!(title:, description:, creator:, status:)
end

# Seed accounts
seed_account "37signals"
seed_account "honcho"
