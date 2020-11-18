defmodule Ppa.Util.Sql do

  def populate_field_table(nil, field, value), do: populate_field(field, value)
  def populate_field_table("", field, value), do: populate_field(field, value)
  def populate_field_table(table, field, value) do
    populate_field("#{table}.#{field}", value)
  end

  def populate_or_omit_field_table(nil, field, value), do: populate_or_omit_field(field, value)
  def populate_or_omit_field_table("", field, value), do: populate_or_omit_field(field, value)
  def populate_or_omit_field_table(table, field, value) do
    populate_or_omit_field("#{table}.#{field}", value)
  end

  def populate_field("", _), do: ""
  def populate_field(name, nil), do: "#{name} is NULL"
  def populate_field(name, []), do: "#{name} is NULL"
  def populate_field(name, "is not null"), do: "#{name} is NOT NULL"
  def populate_field(name, value) when is_list(value), do: "#{name} in (#{Enum.join(value, ",")})"
  def populate_field(name, value), do: "#{name} = #{value}"


  def populate_or_omit_field(_, []), do: ""
  def populate_or_omit_field(_, nil), do: ""
  def populate_or_omit_field(name, value) when is_list(value), do: "#{name} in (#{Enum.join(value, ",")})"
  def populate_or_omit_field(name, value), do: "#{name} = #{value}"

  def and_if_not_empty(clause) do
    if clause == "", do: "", else: "AND #{clause}"
  end

  def quotes(input) do
    Enum.map(input, &("'#{:string.replace(&1, "'", "''")}'"))
  end

  def quote_field(nil), do: nil
  def quote_field(input), do: "'#{input}'"
end
