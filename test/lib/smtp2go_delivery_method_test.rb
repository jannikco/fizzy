require "test_helper"

class Smtp2goDeliveryMethodTest < ActiveSupport::TestCase
  ENDPOINT = "https://api.smtp2go.com/v3/email/send"

  setup do
    @delivery_method = Smtp2goDeliveryMethod.new(api_key: "api-test-key")
  end

  test "maps a multipart message to the SMTP2GO payload" do
    stub_smtp2go

    @delivery_method.deliver! multipart_mail

    assert_equal "api-test-key", @request.headers["X-Smtp2go-Api-Key"]
    assert_equal "Fizzy <support@fizzy.do>", payload["sender"]
    assert_equal [ "Alice <alice@example.com>" ], payload["to"]
    assert_equal "Hello", payload["subject"]
    assert_equal "Plain body", payload["text_body"]
    assert_includes payload["html_body"], "<p>HTML body</p>"
    assert_includes payload["custom_headers"], { "header" => "List-Unsubscribe", "value" => "<https://example.com/unsub>" }
  end

  test "encodes attachments as base64" do
    stub_smtp2go

    @delivery_method.deliver! mail_with_attachment

    attachment = payload["attachments"].sole
    assert_equal "report.csv", attachment["filename"]
    assert_equal "text/csv", attachment["mimetype"]
    assert_equal "id,name\n1,Ana\n", Base64.strict_decode64(attachment["fileblob"])
  end

  test "omits blank fields" do
    stub_smtp2go

    @delivery_method.deliver! multipart_mail

    assert_not payload.key?("cc")
    assert_not payload.key?("bcc")
  end

  test "raises when the API reports a failed delivery" do
    stub_smtp2go(succeeded: 0, failed: 1, failures: [ "bad@address" ])

    assert_raises Smtp2goDeliveryMethod::DeliveryError do
      @delivery_method.deliver! multipart_mail
    end
  end

  test "raises on a non-2xx response" do
    stub_smtp2go(status: 401, error: "permission denied")

    assert_raises Smtp2goDeliveryMethod::DeliveryError do
      @delivery_method.deliver! multipart_mail
    end
  end

  private
    def stub_smtp2go(status: 200, **data)
      data = { succeeded: 1, failed: 0 }.merge(data)

      stub_request(:post, ENDPOINT)
        .with { |request| @request = request }
        .to_return(status: status, headers: { "Content-Type" => "application/json" }, body: { data: data }.to_json)
    end

    def payload
      @payload ||= JSON.parse(@request.body)
    end

    def multipart_mail
      mail = Mail.new
      mail.from = "Fizzy <support@fizzy.do>"
      mail.to = "Alice <alice@example.com>"
      mail.subject = "Hello"
      mail["List-Unsubscribe"] = "<https://example.com/unsub>"
      mail.text_part = Mail::Part.new { body "Plain body" }
      mail.html_part = Mail::Part.new do
        content_type "text/html; charset=UTF-8"
        body "<p>HTML body</p>"
      end
      mail
    end

    def mail_with_attachment
      mail = Mail.new
      mail.from = "Fizzy <support@fizzy.do>"
      mail.to = "Alice <alice@example.com>"
      mail.subject = "Export ready"
      mail.body = "Your export is attached."
      mail.attachments["report.csv"] = { mime_type: "text/csv", content: "id,name\n1,Ana\n" }
      mail
    end
end
