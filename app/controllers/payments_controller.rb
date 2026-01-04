class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_employer
  before_action :set_job, only: [:create, :success, :cancel]

  # POST /payments/create
  # Creates a PayPal order for job posting payment
  def create
    # For now, we'll create a simple payment record
    # Full PayPal integration would use the paypal-server-sdk

    # Check if job already paid
    if @job.payment_date.present?
      redirect_to @job, alert: "This job has already been paid for."
      return
    end

    # Store the job ID in session for the callback
    session[:pending_payment_job_id] = @job.id

    # In production, this would redirect to PayPal
    # For now, redirect to a simulated payment page
    redirect_to payment_confirm_path(job_id: @job.id)
  end

  # GET /payments/confirm
  # Shows payment confirmation page (simulated for development)
  def confirm
    @job = current_user.jobs.find(params[:job_id])
    @price = JOB_POSTING_PRICE
    @currency = JOB_POSTING_CURRENCY
  end

  # POST /payments/process
  # Processes the payment (simulated for development)
  def process_payment
    @job = current_user.jobs.find(params[:job_id])

    # Check for coupon
    coupon = nil
    if params[:coupon_code].present?
      coupon = Coupon.find_by(code: params[:coupon_code].upcase)
    end

    amount = JOB_POSTING_PRICE.to_f
    if coupon
      amount = [amount - coupon.value.to_f, 0].max
    end

    # Mark as paid
    @job.update!(
      payment_amount: amount,
      payment_type: amount > 0 ? "paypal" : "coupon",
      payment_date: Date.current,
      payment_comment: coupon ? "Coupon: #{coupon.code}" : nil,
      approved: true  # Auto-approve paid jobs
    )

    redirect_to @job, notice: "Payment successful! Your job has been posted."
  end

  # GET /payments/success
  # PayPal success callback
  def success
    if @job.update(
      payment_amount: JOB_POSTING_PRICE.to_f,
      payment_type: "paypal",
      payment_date: Date.current,
      approved: true
    )
      session.delete(:pending_payment_job_id)
      redirect_to @job, notice: "Payment successful! Your job has been posted."
    else
      redirect_to @job, alert: "Payment recorded but there was an issue. Please contact support."
    end
  end

  # GET /payments/cancel
  # PayPal cancel callback
  def cancel
    session.delete(:pending_payment_job_id)
    redirect_to @job, alert: "Payment was cancelled. Your job is saved but not yet published."
  end

  private

  def ensure_employer
    unless current_user.employer?
      redirect_to root_path, alert: t("flash.not_authorized")
    end
  end

  def set_job
    @job = current_user.jobs.find(params[:job_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to jobs_path, alert: "Job not found."
  end
end
