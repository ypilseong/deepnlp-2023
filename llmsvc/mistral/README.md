# Mistral 7B - Quickstart

Mistral AI provides ready-to-use Docker images on the Github registry. The weights are distributed separately.

To run the image, you need a cloud virtual machine with at least 24GB of vRAM for good throughput and float16 weights. Other inference stacks can lower these requirements to 16GB vRAM.

## Running an inference server using Docker + vLLM[](https://docs.mistral.ai/quickstart//#running-an-inference-server-using-docker--vllm "Direct link to Running an inference server using Docker + vLLM")

On a GPU-enabled host, you can run the Mistral AI LLM Inference image with the following command to download the model from Hugging Face:

```
docker run --gpus all \
    -e HF_TOKEN=$HF_TOKEN -p 8000:8000 \
    ghcr.io/mistralai/mistral-src/vllm:latest \
    --host 0.0.0.0 \
    --model mistralai/Mistral-7B-v0.1
```

Where `HF_TOKEN` is an environment variable containing your [Hugging Face user access token](https://huggingface.co/docs/hub/security-tokens).

If you have downloaded the weights in the Hugging Face format on your local instance in the folder `/path/to/model`, you can directly run:

```
docker run --gpus all \
    -p 8000:8000 \
    -v /path/to/model/:/mnt/model/ \
    ghcr.io/mistralai/mistral-src/vllm:latest \
    --host 0.0.0.0 \    --model="/mnt/model/"
```

This will spawn a vLLM instance exposing an OpenAI-like API, as documented in the [API section](https://docs.mistral.ai/api).

info

If your GPU has CUDA capabilities below 8.0, you will see the error `ValueError: Bfloat16 is only supported on GPUs with compute capability of at least 8.0. Your XXX GPU has compute capability 7.0`. You need to pass the parameter `--dtype half` to the Docker command line.

## Running an inference server using vLLM[](https://docs.mistral.ai/quickstart//#running-an-inference-server-using-vllm "Direct link to Running an inference server using vLLM")

Alternatively, you can directly spawn a vLLM server on a GPU-enabled host with Cuda 11.8.

### Install vLLM[](https://docs.mistral.ai/quickstart//#install-vllm "Direct link to Install vLLM")

Firstly you need to install vLLM (or use `conda add vllm` if you are using Anaconda):

```
pip install vllm
```

### Log in to the Hugging Face hub[](https://docs.mistral.ai/quickstart//#log-in-to-the-hugging-face-hub "Direct link to Log in to the Hugging Face hub")

You will also need to log in to the Hugging Face hub using:

```
huggingface-cli login
```

### Run the OpenAI compatible inference endpoint[](https://docs.mistral.ai/quickstart//#run-the-openai-compatible-inference-endpoint "Direct link to Run the OpenAI compatible inference endpoint")

You can then use the following command to start the server:

```
python -u -m vllm.entrypoints.openai.api_server --host 0.0.0.0 --model mistralai/Mistral-7B-v0.1
```

## Next steps[](https://docs.mistral.ai/quickstart//#next-steps "Direct link to Next steps")

Once the server is running, you can use any OpenAI-compatible client to interact with it, or directly implement the routes you need as described in the [API documentation](https://docs.mistral.ai/api).
