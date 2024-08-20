defmodule WaultWeb.LiveView.Fileview do
  use WaultWeb, :live_view

  import Wault.FsObjects.Context,
    only: [
      get_object_via_path: 2,
      get_fs_object_children: 2,
      get_child_by_name: 2,
      go_back: 1,
      get_fs_object_by_id: 1,
      get_nav_stack_from_object: 1,
      create_fs_object: 2,
      short_dest: 1
    ]

  def render(assigns) do
    ~H"""
    <div class="flex flex-col md:flex-row">
      <div class="p-4 w-500px border-r border-slate-300 space-y-2">
        <div>
          <h2 class="font-semibold"><%= @file.name %></h2>
          <h3 class="text-slate-400"><%= @file.inserted_at %></h3>
        </div>
        <div>
          <%= for tag <- @file.tags do %>
            <span class="bg-slate-200 text-slate-800 rounded-full px-2 py-1 text-xs mr-2">
              <%= tag.name %>
            </span>
          <% end %>
        </div>
        <h2>Add tags</h2>
        <form phx-submit="append_tags">
          <input type="text" name="new_tags" value="" placeholder="tag..." class="rounded-md" />
        </form>
      </div>
      <div class="p-4 w-full flex justify-around">
        <%= case Path.extname(@file.file) do %>
          <% ".mp4" -> %>
            <video
              class="rounded-md"
              controls
              src={static_path(@socket, "/uploads/#{"live_view_upload-" <> @file.file}")}
            >
            </video>
          <% _ -> %>
            <img
              class="max-w-[85%] rounded-md"
              src={static_path(@socket, "/uploads/#{"live_view_upload-" <> @file.file}")}
            />
        <% end %>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    path =
      params["path"]
      |> String.split("/")
      |> Enum.reject(&(&1 == ""))

    case get_object_via_path(nil, path) do
      {:error, _} ->
        {:error, "Path not found"}

      {:ok, %{type: "dir"}} ->
        # redirect to /storage?path=...
        {:ok, push_patch(socket, to: "/storage", query: %{"path" => Enum.join(path, "/")})}

      {:ok, file} ->
        socket =
          socket
          |> assign(file: file)

        {:ok, socket}
    end
  end

  def handle_event("append_tags", %{"new_tags" => tags}, socket) do
    IO.inspect(tags, label: "tags")

    {:noreply, socket}
  end
end
