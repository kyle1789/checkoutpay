# app/controllers/api/charges_controller.rb
module Api
  class ChargesController < ApplicationController
    before_action :set_charge, only: [ :show, :process_charge ]

    def index
      charges = Charge.order(created_at: :desc)
      render json: charges, status: :ok
    end

    def show
      render json: @charge, status: :ok
    end

    def create
      charge, created = Payments::ChargeCreator.call(charge_params.to_h, require_key: true)

      if created
        render json: charge, status: :created
      else
        render json: charge, status: :ok
      end
    rescue Payments::ChargeCreator::MissingIdempotencyKey
      render json: { error: "idempotency_key is required" }, status: :unprocessable_entity
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages, message: e.message }, status: :unprocessable_entity
    end

    def process_charge
      ChargeProcessorWorker.perform_async(@charge.id)
      render json: { message: "Processing started", charge_id: @charge.id }, status: :accepted
    end

    private

    def charge_params
      params.require(:charge).permit(:idempotency_key, :amount_cents, :currency, :description)
    end

    def set_charge
      @charge = Charge.find(params[:id])
    end
  end
end
