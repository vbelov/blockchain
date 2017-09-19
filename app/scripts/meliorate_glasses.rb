class MeliorateGlasses
  def run
    ActiveRecord::Base.logger.silence do
      do_run
    end
  end

  def do_run
    Stock.all.each do |stock_code|
      puts "processing glasses for #{stock_code}"

      total_orders = 0
      orders_left = 0
      batch_size = 1_000
      sql = Glass.where(stock_code: stock_code)
      total = sql.count

      sql.find_in_batches(batch_size: batch_size).with_index do |glasses, index|
        puts "processing batch of glasses #{index} / #{total / batch_size}"
        updates = []

        glasses.each do |glass|
          update = {id: glass.id}
          %i(buy sell).each do |action|
            json = glass.send("#{action}_orders")
            raw_orders = JSON.parse(json)

            total_orders += raw_orders.count
            base_volume = 0
            orders_to_keep = raw_orders.take_while do |rate, order_target_volume|
              rate = rate.to_f
              res = base_volume < Stocks::Base.max_glass_volume
              base_volume += rate * order_target_volume
              res
            end
            orders_to_keep.map! { |r| r.map(&:to_f) }
            orders_left += orders_to_keep.count
            update[:"#{action}_orders"] = orders_to_keep.to_json
          end
          updates << update
        end

        conn = Glass.connection
        columns = updates.first.keys.map { |column_name| Glass.columns_hash[column_name.to_s] }
        values_clause = updates.map do |obj|
          value_clause = columns.map { |col| conn.quote(obj[col.name.to_sym]) }.join(',')
          "(#{value_clause})"
        end.join(',')

        update_sql = "
          update glasses set
              buy_orders = updates.buy_orders, sell_orders = updates.sell_orders
          from (values #{values_clause}) as updates(glass_id, buy_orders, sell_orders)
          where updates.glass_id = glasses.id;
        "
        conn.execute(update_sql)
      end

      puts "total_orders: #{total_orders}"
      puts "orders_left: #{orders_left}"
      puts "left: #{(orders_left.to_f / total_orders.to_f * 100.0).round(1)} %"
    end

    true
  end
end
