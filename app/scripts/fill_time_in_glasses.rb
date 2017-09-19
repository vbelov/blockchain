class FillTimeInGlasses
  def run
    Stock.all.each do |stock_code|
      puts "processing glasses for #{stock_code}"
      batch_size = 1_000
      sql = Glass.where(stock_code: stock_code)
      total = sql.count
      sql.find_in_batches(batch_size: batch_size).with_index do |glasses, index|
        puts "processing batch of glasses #{index} / #{total / batch_size}"
        updates = glasses.map do |glass|
          t0 = glass.created_at
          t1 = t0.at_beginning_of_minute
          t2 = t1 + 1.minute
          t = (t2 - t0 > t0 - t1) ? t1 : t2
          {id: glass.id, time: t}
        end

        conn = Glass.connection
        columns = updates.first.keys.map { |column_name| Glass.columns_hash[column_name.to_s] }
        values_clause = updates.map do |obj|
          value_clause = columns.map { |col| conn.quote(obj[col.name.to_sym]) }.join(',')
          "(#{value_clause})"
        end.join(',')

        update_sql = "
          update glasses set
              time = updates.time::timestamp without time zone
          from (values #{values_clause}) as updates(glass_id, time)
          where updates.glass_id = glasses.id;
        "
        conn.execute(update_sql)
      end
    end
  end
end
