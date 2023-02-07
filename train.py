import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torch.nn.utils.rnn import pad_sequence
from torch.nn import TransformerEncoder, TransformerEncoderLayer
import math
from typing import Tuple
from model import model
from dataset_classes import PatientEncounter
import pandas as pd

# Use cuda if available
device = "cuda" if torch.cuda.is_available() else "cpu"

# Load data
patients = pd.read_csv("data/patients.csv",)
encounters = pd.read_csv("data/admissions.csv")
lab_events = pd.read_csv("data/lab_events.csv")
labels = pd.read_csv("data/labels.csv")

# Define a custom collate function to pad tensors in X to the same size
def collate_fn(batch):
    X, y = zip(*batch)
    X_patient = [x[0] for x in X]
    X_encounter = [x[1] for x in X]
    X_lab_events = [x[2] for x in X]
    X_lab_events_padded = pad_sequence(X_lab_events, batch_first=True, padding_value=0)
    X_lab_events_padded = [x.unsqueeze(0) for x in X_lab_events_padded]
    y = torch.cat(y, dim=0)
    return X_patient, X_encounter, X_lab_events_padded, y

# Define the dataset and dataloader
train_data = PatientEncounter(patients, encounters, lab_events, labels)
train_dataloader = DataLoader(train_data, batch_size=64, shuffle=False, collate_fn=collate_fn)

# Define loss function and optimizer
criterion = nn.BCELoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

# Train the model
num_epochs = 10
for epoch in range(num_epochs):
    running_loss = 0.0
    for i, data in enumerate(train_dataloader):
        X, y = data
        X = [x.to(device) for x in X]
        y = y.to(device)
        optimizer.zero_grad()
        outputs = model(X)
        loss = criterion(outputs, y)
        loss.backward()
        optimizer.step()
        running_loss += loss.item()
        if i % 100 == 99:
            print('[%d, %5d] loss: %.3f' % (epoch + 1, i + 1, running_loss / 100))
            running_loss = 0.0

# TODO: Add evaluation code
# TODO: Add code to save model
