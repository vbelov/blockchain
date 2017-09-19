module ApplicationHelper
  def highlight_arbitrage(er, action)
    'success' if er.arbitrage_on && er.arbitrage_on.include?(action)
  end

  def graphs_nav_class(_module)
    controller_path =~ /#{_module}/ ? 'active' : ''
  end
end
