module Stocks
  module CrossPairs
    def refresh_cross_pairs
      cross_pairs.each do |stock_pair|
        refresh_cross_pair(stock_pair)
      end
    end

    def refresh_cross_pair(stock_pair)
      base_pair = stock_pair.base_pair
      target_pair = stock_pair.target_pair

      base_glass = Glass.where(
          stock_code: stock_code,
          target_code: base_pair.target_code,
          base_code: base_pair.base_code,
      ).order(time: :desc).first
      return unless base_glass

      target_glass = Glass.where(
          stock_code: stock_code,
          target_code: target_pair.target_code,
          base_code: target_pair.base_code,
          time: base_glass.time,
      ).first

      merge_glasses(base_glass, target_glass) if target_glass
    end

    def merge_glasses(base_glass, target_glass)
      # Например ETH/BTC через пары BTC/CNY (base_glass) и ETH/CNY (target_glass)
      # sell: sell ETH for CNY, buy BTC for CNY
      sell_orders = merge_order_books(
          JSON.parse(target_glass.sell_orders),
          JSON.parse(base_glass.buy_orders)
      )

      # buy: sell BTC for CNY, buy ETH for CNY
      buy_orders = merge_order_books(
          JSON.parse(target_glass.buy_orders),
          JSON.parse(base_glass.sell_orders)
      )

      Glass.create!(
          stock_code: base_glass.stock_code,
          target_code: target_glass.target_code,
          base_code: base_glass.target_code,
          buy_orders: buy_orders.to_json,
          sell_orders: sell_orders.to_json,
          time: base_glass.time,
      )
    end

    def merge_order_books(book1, book2)
      book1_iterator = book1.to_enum
      book2_iterator = book2.to_enum

      top_order1 = book1_iterator.next
      top_order2 = book2_iterator.next
      orders = []

      loop do
        rate1 = top_order1[0]
        c1_volume = top_order1[1]
        c0_volume_1 = rate1 * c1_volume

        rate2 = top_order2[0]
        c2_volume = top_order2[1]
        c0_volume_2 = rate2 * c2_volume

        if c0_volume_1 < c0_volume_2
          c0_volume = c0_volume_1

          # создаем ордер
          rate = rate1 / rate2
          orders << [rate, c1_volume]

          # уменьшаем остающийся ордер
          top_order2[1] = c2_volume - c0_volume / rate2

          # переходим на след. ордер
          top_order1 = book1_iterator.next
        else
          c0_volume = c0_volume_2

          # создаем ордер
          c1_volume_to_take = c0_volume / rate1
          rate = rate1 / rate2
          orders << [rate, c1_volume_to_take]

          # уменьшаем остающийся ордер
          top_order1[1] = c1_volume - c1_volume_to_take

          # переходим на след. ордер
          top_order2 = book2_iterator.next
        end
      end

      orders
    end
  end
end
