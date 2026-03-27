# app/services/payments/fake_gateway.rb
module Payments
  class FakeGateway
    class TemporaryError < StandardError; end
    class PermanentError < StandardError; end

    def self.charge!(payload)
      amount_cents    = payload[:amount_cents]
      currency        = payload[:currency].presence || "BRL"
      idempotency_key = payload[:idempotency_key]&.to_s&.strip

      Rails.logger.info(
        "FakeGateway START | key=#{idempotency_key} | amount_cents=#{amount_cents} | currency=#{currency}"
      )

      if amount_cents.blank? || amount_cents.to_i <= 0
        raise PermanentError, "Invalid amount"
      elsif currency != "BRL" && currency != "USD"
        raise PermanentError, "Invalid currency, must be BRL or USD"
      end

      if rand < 0.3
        raise TemporaryError, "Gateway timeout"
      end

      provider_id = generate_provider_charge_id

      Rails.logger.info(
        "FakeGateway SUCCESS | key=#{idempotency_key} | provider_charge_id=#{provider_id}"
      )

      {
        provider_charge_id: provider_id
      }
    end

    private

    def self.generate_provider_charge_id
      "ch_#{SecureRandom.hex(6)}"
    end
  end
end
