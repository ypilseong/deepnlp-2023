import os

from datasets import load_dataset


data_path = os.environ.get("DATA_PATH")
if not data_path:
    raise ValueError("DATA_PATH environment variable not set")

# Load the dataset
dataset = load_dataset(data_path)
train = dataset['train']

train.to_csv('train.csv', index = False)
