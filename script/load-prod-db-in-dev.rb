#!/usr/bin/env ruby

if ARGV.length != 1
  puts "Usage: #{$0} <dbfile>"
  exit 1
end
original_dbfile = ARGV[0]

require_relative "../config/environment"

unless Rails.env.local?
  abort "This script should only be run in a local development environment."
end

identifier = SecureRandom.hex(4)
signup = Signup.new(
  email_address: "dev-#{identifier}@example.com",
  full_name: "Developer #{identifier}",
  company_name: "Company #{identifier}",
  password: "secret123456"
)

puts "Creating signal identity for #{signup.email_address}..."
signup.send(:create_signal_identity)

puts "Creating queenbee account ..."
signup.send(:create_queenbee_account)

path = ApplicationRecord.tenanted_root_config.database_path_for(signup.tenant_name)
FileUtils.mkdir_p(File.dirname(path), verbose: true)
FileUtils.cp original_dbfile, path, verbose: true

ActiveRecord::Tenanted::DatabaseTasks.migrate_all

ApplicationRecord.with_tenant(signup.tenant_name) do |tenant|
  Account.sole.update! queenbee_id: signup.queenbee_account.id
  User.first.update! signal_user_id: signup.signal_account.owner.id

  puts "\n\nLogin to http://launchpad.localhost:3011/ as #{signup.email_address} / #{signup.password}"
end
