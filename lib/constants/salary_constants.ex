defmodule Constants.SalaryConstants do
  @moduledoc false

  @supported_currencies Map.keys(Money.Currency.all())


  def supported_currencies, do: @supported_currencies
end
