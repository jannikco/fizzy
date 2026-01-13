#! /usr/bin/env ruby

require_relative "../../config/environment"

def migrate_blobs_to_s3
  source_service_name = :local
  target_service_name = :s3

  puts "Starting migration from #{source_service_name} to #{target_service_name}..."
  puts "Total blobs: #{ActiveStorage::Blob.count}"

  report = { updated: 0, skipped: 0, errors: 0 }

  if ActiveStorage::Blob.count == 0
    puts "No blobs found, nothing to migrate."
    return
  end

  # Set up services
  ActiveStorage::Blob.service = source_service = ActiveStorage::Blob.services.fetch(source_service_name)
  target_service = ActiveStorage::Blob.services.fetch(target_service_name)

  # Migrate each blob
  ActiveStorage::Blob.find_each do |blob|
    if target_service.name.to_sym == blob.service_name.to_sym
      report[:skipped] += 1
      putc "-"
    elsif target_service.exist?(blob.key)
      # File already exists in S3, just update the service name
      blob.update_column :service_name, target_service_name
      report[:skipped] += 1
      putc "S"
    else
      begin
        # Upload to S3
        blob.open do |stream|
          target_service.upload(blob.key, stream, checksum: blob.checksum)
        end

        # Update the service name
        blob.update_column :service_name, target_service_name

        report[:updated] += 1
        putc "."
      rescue ActiveStorage::FileNotFoundError => e
        puts "\nError migrating blob #{blob.id}: File not found"
        report[:errors] += 1
        putc "E"
      rescue => e
        puts "\nError migrating blob #{blob.id}: #{e.message}"
        report[:errors] += 1
        putc "E"
      end
    end
  end

  puts "\n\nMigration complete!"
  puts "Updated: #{report[:updated]}"
  puts "Skipped: #{report[:skipped]}"
  puts "Errors: #{report[:errors]}"
end

migrate_blobs_to_s3
