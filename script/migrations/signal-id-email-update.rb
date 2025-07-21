#!/usr/bin/env ruby

require_relative "../config/environment"

CHANGES = [
  { from: "kevin@37signals.com", to: "kevin@basecamp.com" },
  { from: "david@37signals.com", to: "david@hey.com" },
  { from: "jay@37signals.com", to: "jay@basecamp.com" },
  { from: "jeremy@37signals.com", to: "jeremy@basecamp.com" },
  { from: "jillian@37signals.com", to: "jillian@basecamp.com" },
  { from: "jorge@37signals.com", to: "jorge@basecamp.com" },
  { from: "merissa@37signals.com", to: "merissa@basecamp.com" },
  { from: "michelle@37signals.com", to: "michelle@basecamp.com" },
  { from: "scott@37signals.com", to: "scott@basecamp.com" },
  { from: "silvia@37signals.com", to: "silvia@basecamp.com" }
]

ApplicationRecord.with_each_tenant do |tenant|
  CHANGES.each do |change|
    user = User.find_by(email_address: change[:from])
    if user
      puts "Updating user #{user.id} in tenant #{tenant}: #{change[:from]} -> #{change[:to]}"
      user.email_address = change[:to]
      user.save!
    end
  end
end
