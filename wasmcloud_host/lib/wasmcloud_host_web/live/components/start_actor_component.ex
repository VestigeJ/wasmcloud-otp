defmodule StartActorComponent do
  use Phoenix.LiveComponent

  def mount(socket) do
    {:ok,
     socket
     |> assign(:uploads, %{})
     |> allow_upload(:actor, accept: ~w(.wasm), max_entries: 1)}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "start_actor_file",
        %{"replicas" => replicas},
        socket
      ) do
    Phoenix.LiveView.consume_uploaded_entries(socket, :actor, fn %{path: path}, _entry ->
      replicas = 1..String.to_integer(replicas)
      {:ok, bytes} = File.read(path)
      replicas |> Enum.each(fn _ -> HostCore.Actors.ActorSupervisor.start_actor(bytes) end)
    end)

    {:noreply, socket}
  end

  def handle_event(
        "start_actor_ociref",
        %{"replicas" => replicas, "actor_ociref" => actor_ociref},
        socket
      ) do
    replicas = 1..String.to_integer(replicas)

    replicas
    |> Enum.each(fn _ -> HostCore.Actors.ActorSupervisor.start_actor_from_oci(actor_ociref) end)

    {:noreply, socket}
  end

  def render(assigns) do
    submit_action =
      if assigns.id == :start_actor_file_modal do
        "start_actor_file"
      else
        "start_actor_ociref"
      end

    ~L"""
    <form class="form-horizontal" phx-submit="<%= submit_action %>" phx-change="validate" phx-target="<%= @myself %>">
      <input name="_csrf_token" type="hidden" value="<%= Phoenix.Controller.get_csrf_token() %>">
      <%= if assigns.id == :start_actor_file_modal do %>
      <div class="form-group row" phx-drop-target="<%= @uploads.actor.ref %>">
        <label class="col-md-3 col-form-label" for="file-input">File</label>
        <div class="col-md-9">
          <%= live_file_input @uploads.actor %>
        </div>
      </div>
      <% else %>
      <div class="form-group row">
        <label class="col-md-3 col-form-label" for="file-input">OCI reference</label>
        <div class="col-md-9">
          <input class="form-control" id="text-input" type="text" name="actor_ociref" placeholder="wasmcloud.azurecr.io/echo:0.2.0" value="">
          <span class="help-block">Enter an OCI reference</span>
        </div>
      </div>
      <% end %>
      <div class="form-group row">
        <label class="col-md-3 col-form-label" for="text-input">Replicas</label>
        <div class="col-md-9">
          <input class="form-control" id="number-input" type="number" name="replicas" placeholder="1" value="1"><span class="help-block">Enter how many instances of this actor you want</span>
        </div>
      </div>
      <div class="modal-footer">
        <button id="close_modal-<%= @id %>" class="btn btn-secondary" type="button" data-dismiss="modal">Close</button>
        <!-- onClick event closes modal -->
        <button class="btn btn-primary" type="submit" onClick="document.getElementById('close_modal-<%= @id %>').click()">Submit</button>
      </div>
    </form>
    """
  end
end
