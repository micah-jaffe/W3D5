require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_clause = params
      .keys
      .map { |key| "#{key} = ?" }
      .join(" AND ")

    vals = params.values

    data = DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_clause}
    SQL

    self.parse_all(data)
  end
end

class SQLObject
  extend Searchable
end
