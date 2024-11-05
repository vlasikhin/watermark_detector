defmodule WatermarkDetector.Application do
  @moduledoc """
  The main application module for the `WatermarkDetector` application.

  This module initializes and supervises the components of the `WatermarkDetector`.
  It starts a supervised task supervisor to handle asynchronous tasks.
  """

  use Application

  @doc """
  Starts the application.

  Initializes a supervisor with a child process responsible for handling supervised tasks.
  """

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: WatermarkDetector.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: WatermarkDetector.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
