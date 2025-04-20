from transformers import TFDistilBertForSequenceClassification, DistilBertTokenizer
import tensorflow as tf
import os
import numpy as np

current_directory = os.path.dirname(os.path.abspath(__file__))

model_path = os.path.join(current_directory, 'model')

model = TFDistilBertForSequenceClassification.from_pretrained(model_path, num_labels=2)
tokenizer = DistilBertTokenizer.from_pretrained(model_path)

print("Model successfully loaded.")

def preprocess_text(text, max_length=512):
    inputs = tokenizer(
        text,
        max_length=max_length,
        truncation=True,
        padding='max_length', 
        return_tensors="tf"
    )

    print("Preprocessing text is working.")

    return inputs

def is_malicious(url, threshold=0.6):
    print(f"Called is_malicious() with URL: {url}")
    inputs = preprocess_text(url)
    outputs = model(inputs)[0]
    probabilities = tf.nn.softmax(outputs, axis=-1)
    malicious_probability = round(float(probabilities[0][1].numpy()), 5)

    if malicious_probability <= 0.60:
        classification = 'benign'
        classification_message = f"This link appears safe (Probability: {malicious_probability})."
    elif 0.61 <= malicious_probability <= 0.89:
        classification = 'potentially malicious'
        classification_message = f"Caution. This link might be harmful (Probability: {malicious_probability})."
    elif malicious_probability >= 0.90:
        classification = 'likely malicious'
        classification_message = f"Warning. This link is likely malicious (Probability: {malicious_probability})."

    return malicious_probability >= threshold, malicious_probability, classification_message, classification

