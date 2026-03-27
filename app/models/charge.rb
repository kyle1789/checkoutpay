class Charge < ApplicationRecord
  # ==============================
  # 1. CONSTANTES de STATUS
  # ==============================

  STATUSES = %w[pending processing succeeded failed].freeze


  # ==============================
  # 2. VALIDATIONS
  # ==============================

  validates :idempotency_key, presence: true, uniqueness: true
  validates :amount_cents, presence: true,
                           numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true
  validates :status, presence: true,
                     inclusion: { in: STATUSES }


  # ==============================
  # 3. CALLBACKS
  # ==============================

  before_validation :normalize_idempotency_key
  before_validation :set_defaults, on: :create


  # ==============================
  # 4. MÉTODOS PÚBLICOS
  # ==============================

  # ---- Status helpers ----

  def pending?
    status == "pending"
  end

  def processing?
    status == "processing"
  end

  def succeeded?
    status == "succeeded"
  end

  def failed?
    status == "failed"
  end


  # ---- Money helpers ----

  def amount
    amount_cents.to_i / 100.0
  end

  def amount_brl
    formatted = format("%.2f", amount).tr(".", ",")
    "R$ #{formatted}"
  end


  # ---- UI helpers ----

  def status_label
    case status
    when "pending"    then "Pendente"
    when "processing" then "Processando"
    when "succeeded"  then "Pago"
    when "failed"     then "Falhou"
    else status
    end
  end


  # ==============================
  # 5. PRIVATE
  # ==============================

  private

  def normalize_idempotency_key
    self.idempotency_key = idempotency_key.to_s.strip
    self.idempotency_key = nil if idempotency_key.blank?
  end

  def set_defaults
    self.status ||= "pending"
    self.currency ||= "BRL"
  end
end
