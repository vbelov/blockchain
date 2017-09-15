module ApplicationHelper
  def highlight_arbitrage(er, action)
    'success' if er.arbitrage_on && er.arbitrage_on.include?(action)
  end
end
