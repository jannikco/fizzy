require "net/http"
require "base64"

# ActionMailer delivery method that sends mail through the SMTP2GO HTTP API
# (https://api.smtp2go.com/v3/email/send) instead of SMTP. Used on hosts where
# outbound SMTP ports are blocked. Registered in config/initializers/smtp2go.rb.
class Smtp2goDeliveryMethod
  ENDPOINT = URI("https://api.smtp2go.com/v3/email/send")
  TIMEOUT = 15.seconds
  FORWARDED_HEADERS = %w[ List-Unsubscribe List-Unsubscribe-Post Reply-To ].freeze

  class DeliveryError < StandardError; end

  attr_reader :settings

  def initialize(settings)
    @settings = settings
  end

  def deliver!(mail)
    response = post payload_for(mail)
    ensure_delivered! response
    response
  end

  private
    def payload_for(mail)
      {
        sender: mail[:from]&.formatted&.first,
        to: mail[:to]&.formatted,
        cc: mail[:cc]&.formatted,
        bcc: mail[:bcc]&.formatted,
        subject: mail.subject,
        text_body: body_of(mail, "text/plain"),
        html_body: body_of(mail, "text/html"),
        custom_headers: custom_headers_of(mail),
        attachments: attachments_of(mail)
      }.compact_blank
    end

    def body_of(mail, mime_type)
      if mail.multipart?
        part = mail.all_parts.find { |candidate| candidate.mime_type == mime_type && !candidate.attachment? }
        part&.decoded
      elsif mail.mime_type == mime_type
        mail.decoded
      end
    end

    def custom_headers_of(mail)
      FORWARDED_HEADERS.filter_map do |name|
        if field = mail[name]
          { header: name, value: field.to_s }
        end
      end
    end

    def attachments_of(mail)
      mail.attachments.map do |attachment|
        {
          filename: attachment.filename,
          fileblob: Base64.strict_encode64(attachment.body.decoded),
          mimetype: attachment.mime_type
        }
      end
    end

    def post(payload)
      request = Net::HTTP::Post.new(ENDPOINT)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request["X-Smtp2go-Api-Key"] = api_key
      request.body = payload.to_json

      http.request(request)
    end

    def http
      Net::HTTP.new(ENDPOINT.host, ENDPOINT.port).tap do |http|
        http.use_ssl = true
        http.open_timeout = TIMEOUT
        http.read_timeout = TIMEOUT
      end
    end

    def api_key
      settings.fetch(:api_key)
    end

    def ensure_delivered!(response)
      data = parsed_data(response)

      unless response.is_a?(Net::HTTPSuccess) && data["succeeded"].to_i >= 1 && data["failed"].to_i.zero?
        raise DeliveryError, "SMTP2GO delivery failed (HTTP #{response.code}): #{data["error"] || data["failures"] || response.body}"
      end
    end

    def parsed_data(response)
      JSON.parse(response.body.to_s).fetch("data", {})
    rescue JSON::ParserError
      {}
    end
end
