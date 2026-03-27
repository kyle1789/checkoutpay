# app/controllers/charges_controller.rb
class ChargesController < ApplicationController
  before_action :set_charge, only: [ :show, :process_charge ]

  def index
    @charges = Charge.order(created_at: :desc)
  end

  def new
    @charge = Charge.new
  end

  def create
    @charge, created = Payments::ChargeCreator.call(charge_params.to_h, require_key: false)

    if created
      redirect_to @charge, notice: "Cobrança criada com sucesso!"
    else
      redirect_to @charge, notice: "Cobrança já existente, reutilizando idempotency_key."
    end
  rescue ActiveRecord::RecordInvalid => e
    @charge = Charge.new(charge_params)
    @charge.errors.add(:base, e.message)
    render :new, status: :unprocessable_entity
  end

  def show
  end

  def process_charge
    ChargeProcessorWorker.perform_async(@charge.id)
    redirect_to @charge, notice: "Processamento iniciado!"
  end

  private

  def charge_params
    params.require(:charge).permit(:idempotency_key, :amount_cents, :currency, :description)
  end

  def set_charge
    @charge = Charge.find(params[:id])
  end
end
