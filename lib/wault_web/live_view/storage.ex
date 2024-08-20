defmodule WaultWeb.LiveView.Storage do
  use WaultWeb, :live_view

  import Wault.IntStd.PopUntil, only: [pop_until: 2]

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
    <div class="flex flex-col md:flex-row max-w-[1440px] h-full">
      <div class="w-full flex-col flex p-4 space-y-2 md:w-[400px] lg:w-[500px]">
        <div>
          <h1 class="font-bold text-2xl text-zinc-500">Storage</h1>
        </div>
        <.form for={@query} phx-submit="search">
          <.input type="text" name="tags" value="" />
        </.form>
        <div class="bg-indigo-300 border-indigo-700 border px-4 rounded-full text-indigo-700 font-semibold">
          results: <%= length(@children) %>
        </div>
        <h2>Upload file</h2>
        <form
          id="upload-file-form"
          phx-submit="upload_file"
          phx-change="validate"
          class="flex flex-col items-center space-y-2"
        >
          <.live_file_input
            class="text-slate-600 file-input py-1 px-1 rounded-md border-slate-700 border w-full"
            upload={@uploads.file}
          />
          <input class="w-full rounded-md" type="text" name="tags" value="" />
          <button
            class="px-2 py-1 border-slate-800 border text-slate-200 bg-slate-800 rounded-md w-full"
            type="sumbit"
          >
            Upload
          </button>
        </form>
      </div>
      <div class="w-full h-full flex flex-col p-4">
        <div class="flex items-center">
          <div>
            <%= case @folder.parent_id do %>
              <% nil -> %>
                <div class="border-zinc-300 border text-2xl w-12 h-12 rounded-lg text-zinc-700 flex items-center">
                  <span class="mx-auto">&#10005;</span>
                </div>
              <% _ -> %>
                <button
                  phx-click="nav-b"
                  class="border-zinc-300 border text-2xl w-12 h-12 rounded-lg text-zinc-700"
                >
                  &uarr;
                </button>
            <% end %>
          </div>
          <div class="border-zinc-300 border w-full px-2 py-1 rounded-lg text-zinc-600 ml-2 h-12 flex items-center text-lg">
            /<%= for {name, id} <- Enum.reverse @nav_stack do %>
              <button
                phx-click="jmp"
                phx-value-fs_object_id={id}
                class="text-indigo-500 px-1 font-semibold"
              ><%= name %></button>/
            <% end %>
          </div>
          <!-- Hamburger menu -->
          <button></button>
        </div>
        <div class="flex flex-wrap gap-4 p-4">
          <%= for fs_object <- @children do %>
            <div class="flex flex-col">
              <%= case fs_object.type do %>
                <% "dir" -> %>
                  <button phx-click="nav-f" phx-value-dir_name={fs_object.name}>
                    <div class="h-24 w-24 bg-zinc-200 rounded-md flex items-center justify-around">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="1em"
                        height="1em"
                        viewBox="0 0 24 24"
                        class="h-14 w-14 fill-slate-500"
                      >
                        <path d="M4.616 19q-.691 0-1.153-.462T3 17.384V6.616q0-.691.463-1.153T4.615 5h4.981l2 2h7.789q.69 0 1.153.463T21 8.616v8.769q0 .69-.462 1.153T19.385 19zm0-1h14.769q.269 0 .442-.173t.173-.442v-8.77q0-.269-.173-.442T19.385 8h-8.19l-2-2h-4.58q-.269 0-.442.173T4 6.616v10.769q0 .269.173.442t.443.173M4 18V6z" />
                      </svg>
                    </div>
                  </button>
                <% _ -> %>
                  <button phx-click="open-f" phx-value-file_name={fs_object.name}>
                  <div class="h-24 w-24 bg-zinc-200 rounded-md flex items-center justify-around">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      width="1em"
                      height="1em"
                      viewBox="0 0 256 256"
                      class="h-14 w-14 fill-slate-500"
                    >
                      <path d="m212.24 83.76l-56-56A6 6 0 0 0 152 26H56a14 14 0 0 0-14 14v176a14 14 0 0 0 14 14h144a14 14 0 0 0 14-14V88a6 6 0 0 0-1.76-4.24M158 46.48L193.52 82H158ZM200 218H56a2 2 0 0 1-2-2V40a2 2 0 0 1 2-2h90v50a6 6 0 0 0 6 6h50v122a2 2 0 0 1-2 2" />
                    </svg>
                  </div>
                  </button>
              <% end %>
              <h1 class="text-center w-24">
                <%= fs_object.name %>
              </h1>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    path =
      case params["path"] do
        nil ->
          []

        path ->
          path
          |> String.split("/")
          |> Enum.reject(&(&1 == ""))
      end

    {:ok, folder} = get_object_via_path(nil, path)

    nav_stack = get_nav_stack_from_object(folder)
    children = get_fs_object_children(folder, %{})

    socket =
      socket
      |> assign(folder: folder)
      |> assign(children: children)
      |> assign(nav_stack: nav_stack)
      |> assign(query: %{"tags" => ""})
      |> assign(:uploaded_files, [])
      |> allow_upload(:file, accept: ~w(.jpg .png .mp4 .md .docx), max_entries: 1)

    # Temporary upload settings for testing

    {:ok, socket}
  end

  def handle_event("search", %{"tags" => tags}, socket) do
    filters =
      case tags do
        "" -> %{tags: {[], []}}
        _ -> %{tags: Wault.Tags.Parser.parse(tags)}
      end

    current_folder = socket.assigns.folder
    new_children = get_fs_object_children(current_folder, filters)

    socket =
      socket
      |> assign(children: new_children)
      |> assign(query: filters)

    {:noreply, socket}
  end

  def handle_event("nav-f", %{"dir_name" => dir_name}, socket) do
    current_folder = socket.assigns.folder

    new_folder = get_child_by_name(current_folder, dir_name)
    new_children = get_fs_object_children(new_folder, socket.assigns.query)
    new_nav_stack = [{new_folder.name, new_folder.id} | socket.assigns.nav_stack]

    socket =
      socket
      |> assign(folder: new_folder)
      |> assign(children: new_children)
      |> assign(nav_stack: new_nav_stack)

    {:noreply, socket}
  end

  def handle_event("nav-b", _, socket) do
    current_folder = socket.assigns.folder
    {:ok, new_folder} = go_back(current_folder)
    new_children = get_fs_object_children(new_folder, socket.assigns.query)
    new_nav_stack = tl(socket.assigns.nav_stack)

    socket =
      socket
      |> assign(folder: new_folder)
      |> assign(children: new_children)
      |> assign(nav_stack: new_nav_stack)

    {:noreply, socket}
  end

  def handle_event("jmp", %{"fs_object_id" => fs_object_id}, socket) do
    new_folder = get_fs_object_by_id(fs_object_id)
    new_children = get_fs_object_children(new_folder, socket.assigns.query)

    new_nav_stack =
      pop_until(socket.assigns.nav_stack, fn {_, id} ->
        id == String.to_integer(fs_object_id)
      end)

    socket =
      socket
      |> assign(folder: new_folder)
      |> assign(children: new_children)
      |> assign(nav_stack: new_nav_stack)

    {:noreply, socket}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  def handle_event("upload_file", params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
        dest =
          Path.join(
            Application.app_dir(:wault, "priv/static/uploads"),
            Path.basename(path) <> Path.extname(entry.client_name)
          )

        File.cp!(path, dest)

        file_dest =
          dest
          |> Path.basename()
          |> String.split("-")
          |> short_dest()
          |> Enum.join("-")

        new_fs_object = %{
          name: entry.client_name,
          type: "file",
          parent_id: socket.assigns.folder.id,
          file: file_dest
        }

        create_fs_object(
          new_fs_object,
          params["tags"]
          |> String.split(" ")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))
        )

        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  def handle_event("open-f", %{"file_name" => file_name}, socket) do
    path =
      socket.assigns.nav_stack
      |> Enum.map(&elem(&1, 0))

    IO.inspect(path)
    path = [file_name | path]
      |> Enum.reverse()
      |> Enum.join("/")

    IO.inspect(path, label: "path")

    {:noreply, push_navigate(socket, to: "/file?path=#{path}")}
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
