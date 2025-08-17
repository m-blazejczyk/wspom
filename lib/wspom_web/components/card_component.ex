defmodule WspomWeb.CardComponent do

  use Phoenix.Component

  def card(assigns) do
    ~H"""
    <li>
      <a href={@href}
        class="block h-full transition-all duration-200 bg-white border border-gray-200 rounded group hover:shadow-lg hover:border-gray-700 hover:ring-1 hover:ring-gray-700/5">
        <div class="flex items-center p-6">
          <div
            class="flex items-center justify-center flex-shrink-0 w-16 h-16 transition-colors duration-200 rounded group-hover:bg-orange-100">
            <!-- Source: flaticon.com -->
            <img src={@img} aria-label={@label} width="64" height="64"/>
          </div>
          <div class="flex-grow ml-6">
            <h3
              class="text-lg font-semibold text-gray-900 transition-colors duration-200 line-clamp-1 group-hover:text-orange-600">
              <%= @name %>
            </h3>
            <div class="inline-flex items-center mt-1">
              <span class="text-gray-700 rounded">
                <%= @info %>
              </span>
            </div>
          </div>

          <div class="flex-shrink-0 ml-4">
            <svg class="w-5 h-5 text-gray-400 group-hover:text-orange-600 transition-colors duration-200"
              xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5"
              stroke="currentColor" aria-hidden="true" data-slot="icon">
              <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5"></path>
            </svg>
          </div>
        </div>
      </a>
    </li>
    """
  end

  def small_card(assigns) do
    ~H"""
    <li>
      <.link patch={@href}
        class="block h-full transition-all duration-200 bg-white border border-gray-200 rounded group hover:shadow-lg hover:border-gray-700 hover:ring-1 hover:ring-gray-700/5">
        <div class="flex items-center p-4">
          <div
            class="flex items-center justify-center flex-shrink-0 w-8 sm:w-16 h-8 sm:h-16 transition-colors duration-200 rounded group-hover:bg-orange-100">
            <!-- Source: flaticon.com -->
            <img src={@img} aria-label={@label}/>
          </div>
        </div>
      </.link>
    </li>
    """
  end

  def tiny_card_patch(assigns) do
    ~H"""
    <li id={assigns[:id] || false} class={assigns[:class] || false}>
      <.link patch={@href}
        class="block h-full bg-white">
        <%= tiny_card_inside(assigns) %>
      </.link>
    </li>
    """
  end

  def tiny_card_click(assigns) do
    ~H"""
    <li id={assigns[:id] || false} class={assigns[:class] || false}>
      <.link phx-click={@click} data-confirm={@confirm}
        class="block h-full bg-white">
        <%= tiny_card_inside(assigns) %>
      </.link>
    </li>
    """
  end

  defp tiny_card_inside(assigns) do
    ~H"""
    <div class="flex items-center">
      <div
        class="flex items-center justify-center flex-shrink-0 w-8 h-8">
        <!-- Source: flaticon.com -->
        <img class="transition-all duration-200 rounded group-hover:bg-orange-100 border border-gray-200 rounded group hover:shadow-lg hover:border-gray-700 hover:ring-1 hover:ring-gray-700/5"
          src={@img} aria-label={@label} />
      </div>
    </div>
    """
  end
end
