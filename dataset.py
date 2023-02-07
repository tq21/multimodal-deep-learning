import torch
from torch.utils.data import Dataset

# Use cuda if available
device = "cuda" if torch.cuda.is_available() else "cpu"

class PatientEncounter(Dataset):
    '''
    PatientEncounter Dataset class
    '''
    def __init__(self, patients, encounters, lab_events, labels):
        super().__init__()
        self.patients = patients
        self.encounters = encounters
        self.lab_events = lab_events
        self.labels = labels
        self.patient_ids = encounters.subject_id
        self.encounter_ids = encounters.hadm_id

    def __len__(self):
        return len(self.patient_ids)

    def __getitem__(self, index):
        patient_id = self.patient_ids[index]
        encounter_id = self.encounter_ids[index]
        
        # Load data for the given patient-encounter
        data_patient = torch.from_numpy(self.patients.loc[self.patients.subject_id == patient_id].iloc[:, 1:].astype(float).values).to(device)
        data_encounter = torch.from_numpy(self.encounters.loc[(self.encounters.subject_id == patient_id) & (self.encounters.hadm_id == encounter_id)].iloc[:, 2:].astype(float).values).to(device)
        data_lab_events = torch.from_numpy(self.lab_events.loc[(self.lab_events.subject_id == patient_id) & (self.lab_events.hadm_id == encounter_id)].iloc[:, 2:].astype(float).values).to(device)
        X = [data_patient, data_encounter, data_lab_events]
        y = torch.from_numpy(self.labels.loc[(self.labels.subject_id == patient_id) & (self.labels.hadm_id == encounter_id)].READMIT_ONE_WEEK.values).to(device)

        return X, y

class Patient(Dataset):
    '''
    Patient Dataset class
    '''
    def __init__(self, patients, labels):
        super().__init__()
        self.patients = patients
        self.labels = labels
        self.patient_ids = patients.subject_id

    def __len__(self):
        return len(self.patient_ids)

    def __getitem__(self, index):
        patient_id = self.patient_ids[index]
        
        # Load data for the given patient
        data_patient = torch.from_numpy(self.patients.loc[self.patients.subject_id == patient_id].values).to(device)
        X = [data_patient]
        y = torch.from_numpy(self.labels.loc[self.labels.subject_id == patient_id].READMIT_ONE_WEEK.values).to(device)

        return X, y
        