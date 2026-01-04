# PayPal SDK Configuration
# Uses paypal-server-sdk gem

# Set environment (sandbox for development, live for production)
PAYPAL_ENV = Rails.env.production? ? :live : :sandbox

# Credentials should be set in environment variables:
# PAYPAL_CLIENT_ID
# PAYPAL_CLIENT_SECRET

# Job posting pricing (in USD)
JOB_POSTING_PRICE = ENV.fetch("JOB_POSTING_PRICE", "50.00")
JOB_POSTING_CURRENCY = "USD"
