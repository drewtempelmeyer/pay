require "pay/version"
require "pay/engine"
require "pay/billable"
require "pay/receipts"
require "pay/payment"
require "pay/errors"

module Pay
  # Define who owns the subscription
  mattr_accessor :billable_class
  mattr_accessor :billable_table
  mattr_accessor :braintree_gateway

  @@billable_class = "User"
  @@billable_table = @@billable_class.tableize

  mattr_accessor :model_parent_class
  @@model_parent_class = "ApplicationRecord"

  mattr_accessor :chargeable_class
  mattr_accessor :chargeable_table
  @@chargeable_class = "Pay::Charge"
  @@chargeable_table = "pay_charges"

  mattr_accessor :subscription_class
  mattr_accessor :subscription_table
  @@subscription_class = "Pay::Subscription"
  @@subscription_table = "pay_subscriptions"

  # Business details for receipts
  mattr_accessor :application_name
  mattr_accessor :business_address
  mattr_accessor :business_name
  mattr_accessor :support_email

  # Email configuration
  mattr_accessor :send_emails
  @@send_emails = true

  mattr_accessor :email_receipt_subject
  @@email_receipt_subject = "Payment receipt"
  mattr_accessor :email_refund_subject
  @@email_refund_subject = "Payment refunded"
  mattr_accessor :email_renewing_subject
  @@email_renewing_subject = "Your upcoming subscription renewal"
  mattr_accessor :email_action_required_subject
  @@email_action_required_subject = "Confirm your payment"

  mattr_accessor :automount_routes
  @@automount_routes = true

  mattr_accessor :default_product_name
  @@default_product_name = "default"
  mattr_accessor :default_plan_name
  @@default_plan_name = "default"

  mattr_accessor :routes_path
  @@routes_path = "/pay"

  def self.setup
    yield self
  end

  def self.billable_models
    Pay::Billable.includers
  end

  def self.find_billable(processor:, processor_id:)
    billable_models.each do |model|
      if (record = model.find_by(processor: processor, processor_id: processor_id))
        return record
      end
    end

    nil
  end

  def self.user_model
    ActiveSupport::Deprecation.warn("Pay.user_model is deprecated and will be removed in v3. Instead, use `Pay.billable_models` now to support more than one billable model.")

    if Rails.application.config.cache_classes
      @@user_model ||= billable_class.constantize
    else
      billable_class.constantize
    end
  end

  def self.charge_model
    if Rails.application.config.cache_classes
      @@charge_model ||= chargeable_class.constantize
    else
      chargeable_class.constantize
    end
  end

  def self.subscription_model
    if Rails.application.config.cache_classes
      @@subscription_model ||= subscription_class.constantize
    else
      subscription_class.constantize
    end
  end

  def self.receipts_supported?
    charge_model.respond_to?(:receipt) &&
      application_name.present? &&
      business_name &&
      business_address &&
      support_email
  end
end
