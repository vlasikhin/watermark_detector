defmodule WatermarkDetector do
  @moduledoc """
  A module for detecting watermarks in images using a pre-trained model.

  This module loads a pre-trained Vision Transformer model from Bumblebee, processes images,
  and analyzes if they contain watermarks and other objecs based on the model predictions.
  """

  @doc """
  Initializes the model.
  Returns a map.
  """

  def start_link(_) do
    {:ok, load_model()}
  end

  @doc """
  Loads the image classification model and prepares it for watermark detection.

  Fetches the Vision Transformer (ViT) model and its featurizer, sets up the classification
  pipeline with options for batch size and compiler settings, and returns the model's serving structure.
  """

  def load_model do
    IO.puts("Loading model...")
    {:ok, model_info} = Bumblebee.load_model({:hf, "google/vit-base-patch16-224"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "google/vit-base-patch16-224"})

    serving =
      Bumblebee.Vision.image_classification(model_info, featurizer,
        top_k: 5,
        compile: [batch_size: 1],
        defn_options: [compiler: EXLA]
      )

    %{serving: serving}
  end

  @doc """
  Processes an image by converting binary data into a tensor format and running it through the model.
  """
  def process_image(image_binary, %{serving: serving}) do
    {:ok, image} = Image.open(image_binary)
    {:ok, tensor} = Image.to_nx(image)

    Nx.Serving.run(serving, tensor)
  end

  @doc """
  Analyzes an image for watermarks using the model's predictions.

  Checks the predictions returned by `process_image/2` to determine if any label
  indicates a watermark, logo, or text.
  """
  def analyze_watermark(image_binary, model) do
    case process_image(image_binary, model) do
      %{predictions: predictions} ->
        has_watermark =
          Enum.any?(predictions, fn %{label: label, score: score} ->
            (String.contains?(label, "watermark") ||
               String.contains?(label, "text") ||
               String.contains?(label, "logo")) && score > 0.3
          end)

        {:ok, {has_watermark, predictions}}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, :unknown_response}
    end
  end

  @doc """
  Analyzes image for watermarks based using the given source type (:url or :file).

  Downloads or reads the image and checks for watermarks using `analyze_watermark/2`.
  Outputs the result to the console, indicating whether a watermark was detected
  and providing details for each detected element.
  """
  def analyze_image(:url, source) do
    model = load_model()

    IO.puts("Downloading image from #{source}")

    case Req.get(source) do
      {:ok, response} -> process_analysis(response.body, model)
      {:error, reason} -> IO.puts("Image download error: #{inspect(reason)}")
    end
  end

  def analyze_image(:file, source) do
    model = load_model()

    IO.puts("Analyzing file: #{source}")

    case File.read(source) do
      {:ok, image_binary} -> process_analysis(image_binary, model)
      {:error, reason} -> IO.puts("File reading error: #{reason}")
    end
  end

  defp process_analysis(image_binary, model) do
    case analyze_watermark(image_binary, model) do
      {:ok, {has_watermark, predictions}} ->
        IO.puts("\nAnalysis results:")
        IO.puts("Watermark: #{if has_watermark, do: "DETECTED", else: "NOT DETECTED"}")
        IO.puts("\nDetected elements:")

        Enum.each(predictions, fn %{label: label, score: score} ->
          IO.puts("- #{label}: #{Float.round(score * 100, 2)}%")
        end)

      {:error, reason} ->
        IO.puts("Analysis error: #{inspect(reason)}")

      _ ->
        IO.puts("Unexpected response from analysis.")
    end
  end
end
