class ChargeProcessorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: 10

  def perform(charge_id)
    puts "START | #{self.class.name} | jid=#{jid} | queue=#{self.class.get_sidekiq_options['queue']} | #{Time.now}"

    charge = Charge.find(charge_id)

    if charge.succeeded?
      Rails.logger.info("Pagamento concluído | charge_id=#{charge.id}")
      return
    end

    charge.with_lock do
      return if charge.succeeded?

      charge.update!(status: "processing")

      response = Payments::FakeGateway.charge!(gateway_payload(charge))

      charge.update!(
        status: "succeeded",
        provider_charge_id: response[:provider_charge_id],
        error_message: nil
      )
    end

  rescue Payments::FakeGateway::TemporaryError => e
    charge.update!(
      status: "pending",
      error_message: e.message
    )

    Rails.logger.warn("Temporary error processing charge #{charge.id}: #{e.message}")
    raise

  rescue Payments::FakeGateway::PermanentError => e
    charge.update!(
      status: "failed",
      error_message: e.message
    )

    Rails.logger.error("Permanent error processing charge #{charge.id}: #{e.message}")
  end

  private

  def gateway_payload(charge)
    {
      idempotency_key: charge.idempotency_key,
      amount_cents: charge.amount_cents,
      currency: charge.currency
    }
  end
end
