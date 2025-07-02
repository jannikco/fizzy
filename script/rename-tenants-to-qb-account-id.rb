#!/usr/bin/env ruby

require_relative "../config/environment"

tenant_names = []

ApplicationRecord.with_each_tenant do |tenant|
  next if tenant == "#{Rails.env}-tenant"

  account = Account.first
  queenbee_id = account.queenbee_id
  tenant_names << { from: tenant, to: queenbee_id }

  ApplicationRecord.remove_connection
end

pp [ "Tenant name changes:", tenant_names ]

root_config = ApplicationRecord.tenanted_root_config
tenant_names.each do |name|
  from_db_path = root_config.database_path_for(name[:from])
  to_db_path = root_config.database_path_for(name[:to])

  from_path = from_db_path.split("/").take(4).join("/")
  to_path = to_db_path.split("/").take(4).join("/")

  unless from_path == to_path
    FileUtils.move from_path, to_path, verbose: true
  end
end

puts
pp [ "Tenants after renaming:", ApplicationRecord.tenants ]
