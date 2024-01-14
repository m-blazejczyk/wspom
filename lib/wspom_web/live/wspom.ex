defmodule WspomWeb.Live do
  use WspomWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, target: 5, message: "Make a guess:")}
  end

  def render(assigns) do
    ~H"""
    <h2>
      <%= @message %>
    </h2>
    <br/>
    <h2>
      <%= for n <- 1..10 do %>
        <.link class="bg-blue-500 hover:bg-blue-700
          text-white font-bold py-2 px-4 border border-blue-700 rounded m-1"
          phx-click="guess" phx-value-number= {n} >
          <%= n %>
        </.link>
      <% end %>
    </h2>
    """
  end
end
