#!/usr/bin/env ruby

require_relative "../config/environment"

ActiveRecord::Base.logger = Logger.new(File::NULL)

class BootstrapSignalId
  def initialize(dry_run: false)
    @dry_run = dry_run
  end

  def run
    SignalId::Database.on_master do
      ApplicationRecord.with_each_tenant do |tenant|
        puts "\n# tenant: #{tenant}"

        next unless check_account_preconditions
        create_signal_id_account if Account.sole.queenbee_id.nil?

        create_signal_id_users
      end
    end
  end

  def check_account_preconditions
    unless Account.count == 1
      puts "There are #{Account.count} accounts, but exactly one is expected."
      false
    else
      true
    end
  end

  def create_signal_id_account
    owner = SignalId::Identity.find_by_email_address!("kevin@37signals.com")
    print_identity("New owner is:", owner)

    unless @dry_run
      qbattr = queenbee_account_attributes(owner)
      queenbee_account = Queenbee::Remote::Account.create!(qbattr)

      signal_id_account = SignalId::Account.find_by!(queenbee_id: queenbee_account.id)
      signal_id_account.update_column :subdomain, ApplicationRecord.current_tenant

      account = Account.sole
      account.queenbee_id = queenbee_account.id
      account.name = ApplicationRecord.current_tenant
      account.save!
    end
  end

  def create_signal_id_users
    signal_account = Account.sole.signal_account

    User.find_each do |user|
      if !user.system? && user.signal_user_id.nil?
        signal_identities = SignalId::Identity.where(email_address: user.email_address)
        if signal_identities.length > 1
          puts "Multiple identities found for #{user.email_address}:"
          signal_identities.each { |identity| print_identity("  - ", identity) }
          signal_identity = signal_identities.first
        elsif signal_identities.length == 1
          signal_identity = signal_identities.first
          print_identity("Identity for #{user.email_address}:", signal_identity)
        else
          puts "No identity found for #{user.name} (#{user.email_address})"
          signal_identity = nil
        end

        if signal_identity
          unless @dry_run
            signal_user = SignalId::User.find_or_create_by!(identity: signal_identity, account: signal_account)

            user.signal_user_id = signal_user.id
            user.save!
          end
        end
      end
    end
  end

  def print_identity(message = "Identity:", identity)
    pad = " " * message.length
    puts "#{message} #{identity.name} (#{identity.email_address})"
    puts "#{pad    } ID: #{identity.id}"
    puts "#{pad    } Username: #{identity.username}"
  end

  def queenbee_account_attributes(signal_identity)
    {
      skip_remote: true, # Fizzy creates its own local account
      product_name: "fizzy",
      name: account_name,
      owner_identity_id: signal_identity.id,
      trial: false,
      subscription: subscription_attributes,
      remote_request: request_attributes
    }
  end

  def subscription_attributes
    subscription = FreeV1Subscription
    { name: subscription.to_param, price: subscription.price }
  end

  def request_attributes
    { user_agent: "script/bootstrap-signal-id.rb" }
  end

  def account_name
    name = ApplicationRecord.current_tenant
    name += " (Beta)" if Rails.env.beta?
    name
  end
end

BootstrapSignalId.new(dry_run: false).run
