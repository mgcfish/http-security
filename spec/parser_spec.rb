require "spec_helper"
require "security_headers/parser"

describe Parser do
    describe "General parsing" do
    subject { described_class.new.security_headers }

    it "parses excess whitespace" do
      header = " X-Frame-Options : sameorigin "
      expect(subject.parse header).to eq(
        {x_frame_options: "sameorigin"}
      )
    end

    it "is case insensitive" do
      header = " X-Frame-OPTIONS : Sameorigin "
      expect(subject.parse header).to eq(
        {x_frame_options: "Sameorigin"}
      )
    end

    it "handles double quoted directive values" do
      header = 'Strict-Transport-Security: max-age="0"; includeSubDomains'
      expect(subject.parse header).to eq(
        {strict_transport_security: 'max-age="0"; includeSubDomains'}
      )
    end

    it "handles singled quoted directive values" do
      header = "Strict-Transport-Security: max-age='0'; includeSubDomains"
      expect(subject.parse header).to eq({strict_transport_security: "max-age='0'; includeSubDomains"})
    end

    it "handles multiple headers" do
      header = "X-XSS-Protection: 1; mode=block\r\nX-Frame-Options: SAMEORIGIN"
      expect(subject.parse header).to eq([
        {x_xss_protection: "1; mode=block"},
        {x_frame_options: "SAMEORIGIN"}
      ])
    end

    it "handles googles headers" do
      header = #"Expires: -1\r\n" \
      "Server: gws\r\n" \
      "Cache-Control: private, max-age=0\r\n" \
      "Content-Type: text/html; charset=ISO-8859-1\r\n" \
      "Alternate-Protocol: 80:quic,p=0.01\r\n" \
      "X-XSS-Protection: 1; mode=block\r\n" \
      "X-Frame-Options: SAMEORIGIN\r\n"
      "Alternate-Protocol: 80:quic,p=0.01\r\n" \
      "Transfer-Encoding: chunked\r\n\r\n"
      expect(subject.parse header).to eq([
        {cache_control: "private, max-age=0"},
        {x_xss_protection: "1; mode=block"},
        {x_frame_options: "SAMEORIGIN"}
      ])
    end
  end

  describe "X-Frames-Options" do
    subject { described_class.new.security_headers }

    it "parses deny" do
      header = "X-Frame-Options: deny"
      expect(subject.parse header).to eq(
        {x_frame_options: "deny"}
      )
    end

    it "parses allow-from" do
      header = "X-Frame-Options: allow-from http://www.example.com"
      expect(subject.parse header).to eq(
        {x_frame_options: "allow-from http://www.example.com"}
      )
    end

    it "parses sameorigin" do
      header = "X-Frame-Options: sameorigin"
      expect(subject.parse header).to eq(
        {x_frame_options: "sameorigin"}
      )
    end
  end

  describe "Strict-Transport-Security" do
    subject { described_class.new.security_headers }

    it "accepts only max-age" do
      header = "Strict-Transport-Security: max-age=31536000"
      expect(subject.parse header).to eq(
        {strict_transport_security: "max-age=31536000"}
      )
    end

    it "accepts max-age of zero" do
      header = "Strict-Transport-Security: max-age=0"
      expect(subject.parse header).to eq(
        {strict_transport_security: "max-age=0"}
      )
    end

    it "accepts max-age then includeSubdomains" do
      header = "Strict-Transport-Security: max-age=0; includeSubDomains"
      expect(subject.parse header).to eq(
        {strict_transport_security: "max-age=0; includeSubDomains"}
      )
    end

    it "accepts includeSubdomains then max-age" do
      header = "Strict-Transport-Security: includeSubDomains; max-age=0"
      expect(subject.parse header).to eq(
        {strict_transport_security: "includeSubDomains; max-age=0"}
      )
    end
  end

  describe "X-Content-Type-Options" do
    subject { described_class.new.security_headers }

    it "accepts nosniff" do
      header = "X-Content-Type-Options: nosniff"
      expect(subject.parse header).to eq(
        { x_content_type_options: "nosniff"}
      )
    end
  end

  describe "X-XSS-Protection" do
    subject { described_class.new.security_headers }

    it "it accepts 1; mode=block" do
      header = "X-XSS-Protection: 1; mode=block"
      expect(subject.parse header).to eq(
        { x_xss_protection: "1; mode=block" }
      )
    end

    it "it accepts 0; mode=block" do
      header = "X-XSS-Protection: 0; mode=block"
      expect(subject.parse header).to eq(
        { x_xss_protection: "0; mode=block" }
      )
    end

    it "it accepts 1" do
      header = "X-XSS-Protection: 1"
      expect(subject.parse header).to eq(
        { x_xss_protection: "1" }
      )
    end
  end

  describe "Cache-Control" do
    subject { described_class.new.security_headers }

    it "it accepts private" do
      header = "Cache-Control: private"
      expect(subject.parse header).to eq(
        { cache_control: "private" }
      )
    end

    it "it accepts public, max-age=1" do
      header = "Cache-Control: public, max-age=1"
      expect(subject.parse header).to eq(
        { cache_control: "public, max-age=1" }
      )
    end

    it "it accepts all recommended value: private, max-age=0, no-cache" do
      header = "Cache-Control: private, max-age=0, no-cache"
      expect(subject.parse header).to eq(
        { cache_control: "private, max-age=0, no-cache" }
      )
    end
  end

  describe "Pragma" do
    subject { described_class.new.security_headers }

    it "accepts no-cache" do
      header = "pragma: no-cache"
      expect(subject.parse header).to eq(
        { pragma: "no-cache" }
      )
    end
  end

  describe "Expires" do
    subject { described_class.new.security_headers }

    it "parses rfc1123-date" do
      header = "Expires: Thu, 04 Dec 2015 16:00:00 GMT"
      expect(subject.parse header).to eq(
        { expires: "Thu, 04 Dec 2015 16:00:00 GMT" }
      )
    end

    it "parses rfc850-date" do
      header = "Expires: Thursday, 04-Dec-15 16:00:00 GMT"
      expect(subject.parse header).to eq(
        { expires: "Thursday, 04-Dec-15 16:00:00 GMT" }
      )
    end

    it "parses asctime-date format #1" do
      header = "Expires: Thu Dec 04 16:00:00 2015"
      expect(subject.parse header).to eq(
        { expires: "Thu Dec 04 16:00:00 2015" }
      )
    end

    it "parses asctime-date format #2" do
      header = "Expires: Thu Dec  4 16:00:00 2015"
      expect(subject.parse header).to eq(
        { expires: "Thu Dec  4 16:00:00 2015" }
      )
    end
  end

  describe "Expires" do
    subject { described_class.new.security_headers }

    it "parses rfc1123-date" do
      header = "Expires: Thu, 04 Dec 2015 16:00:00 GMT"
      expect(subject.parse header).to eq(
        { expires: "Thu, 04 Dec 2015 16:00:00 GMT" }
      )
    end

    it "parses rfc850-date" do
      header = "Expires: Thursday, 04-Dec-15 16:00:00 GMT"
      expect(subject.parse header).to eq(
        { expires: "Thursday, 04-Dec-15 16:00:00 GMT" }
      )
    end

    it "parses asctime-date format #1" do
      header = "Expires: Thu Dec 04 16:00:00 2015"
      expect(subject.parse header).to eq(
        { expires: "Thu Dec 04 16:00:00 2015" }
      )
    end

    it "parses asctime-date format #2" do
      header = "Expires: Thu Dec  4 16:00:00 2015"
      expect(subject.parse header).to eq(
        { expires: "Thu Dec  4 16:00:00 2015" }
      )
    end
  end

  describe "X-Permitted-Cross-Domain-Policies" do
    subject { described_class.new.security_headers }

    it "accepts none" do
      header = "X-Permitted-Cross-Domain-Policies: none"
      expect(subject.parse header).to eq(
        { x_permitted_cross_domain_policies: "none" }
      )
    end

    it "accepts master-only" do
      header = "X-Permitted-Cross-Domain-Policies: master-only"
      expect(subject.parse header).to eq(
        { x_permitted_cross_domain_policies: "master-only" }
      )
    end

    it "accepts by-content-type" do
      header = "X-Permitted-Cross-Domain-Policies: by-content-type"
      expect(subject.parse header).to eq(
        { x_permitted_cross_domain_policies: "by-content-type" }
      )
    end

    it "accepts by-ftp-filename" do
      header = "X-Permitted-Cross-Domain-Policies: by-ftp-filename"
      expect(subject.parse header).to eq(
        { x_permitted_cross_domain_policies: "by-ftp-filename" }
      )
    end

    it "accepts all" do
      header = "X-Permitted-Cross-Domain-Policies: all"
      expect(subject.parse header).to eq(
        { x_permitted_cross_domain_policies: "all" }
      )
    end
  end

  describe "Content-Security-Policy" do
    it "accepts default-src 'self'" do
      header = "Content-Security-Policy: default-src 'self';"
      expect(subject.parse header).to eq(
        { content_security_policy: "default-src 'self';" }
      )
    end

    it "accepts default-src 'self'; script-src 'self';" do
      header = "Content-Security-Policy: default-src 'self'; script-src 'self';"
      expect(subject.parse header).to eq(
        { content_security_policy: "default-src 'self'; script-src 'self';" }
      )
    end

    it "accepts a domain" do
      header = "Content-Security-Policy: default-src 'self' trustedscripts.foo.com"
      expect(subject.parse header).to eq(
        { content_security_policy: "default-src 'self' trustedscripts.foo.com" }
      )
    end

    it "accepts img-src and media-src" do
      header = "Content-Security-Policy: default-src 'self'; img-src 'self' data:; media-src mediastream:"
      expect(subject.parse header).to eq(
        { content_security_policy: "default-src 'self'; img-src 'self' data:; media-src mediastream:" }
      )
    end


  end
end
