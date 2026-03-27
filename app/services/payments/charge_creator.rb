# app/services/payments/charge_creator.rb
module Payments
  class ChargeCreator
    IDEMPOTENCY_PREFIX = "chk_".freeze
    class MissingIdempotencyKey < StandardError; end

    def self.call(attrs, require_key: false)
      new(attrs, require_key: require_key).call
    end

    def initialize(attrs, require_key:)
      @attrs = attrs
      @require_key = require_key
    end

    def call
      key = normalized_idempotency_key
      if key.blank?
        raise MissingIdempotencyKey if require_key
        key = generated_idempotency_key
      end


      begin
        charge = Charge.find_or_create_by!(idempotency_key: key) do |c|
          c.assign_attributes(build_charge_attributes(key))
          c.status ||= "pending"
        end

        created = charge.previously_new_record?
        Rails.logger.info("Key = #{key}, ID = #{charge.id}, status = #{charge.status}, created=#{created}")

      rescue ActiveRecord::RecordNotUnique
        charge = Charge.find_by!(idempotency_key: key)
        created = false
      end

      [ charge, created ]
    end


    # ==============================
    # 4) PRIVATE HELPERS
    # ==============================

    private

    attr_reader :attrs, :require_key


    def normalized_idempotency_key
      attrs[:idempotency_key]&.to_s&.strip
    end

    def generated_idempotency_key
        "#{IDEMPOTENCY_PREFIX}#{SecureRandom.uuid}"
    end

    def build_charge_attributes(key)
      {
        amount_cents: attrs[:amount_cents],
        currency: attrs[:currency].presence || "BRL",
        description: attrs[:description]
      }
    end
  end
end
