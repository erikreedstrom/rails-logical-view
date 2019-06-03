# Provides formatting and other utility methods for views
#
module CurrencyHelper
  # Formats a value as USD
  #
  def format_usd(value)
    "$#{'%.2f' % value}"
  end
end
