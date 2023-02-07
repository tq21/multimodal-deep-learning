import math
import torch
from torch import nn, Tensor
import torch.nn.functional as F
from torch.nn.utils.rnn import pad_sequence
from torch.nn import TransformerEncoder, TransformerEncoderLayer
import math

# Use cuda if available
device = "cuda" if torch.cuda.is_available() else "cpu"

class LabModule(nn.Module):
    '''
    Lab specific module, which takes in a batch of lab events and outputs a batch of lab embeddings.
    '''
    def __init__(self, num_lab_types):
        super().__init__()
        self.lab_type = nn.Linear(in_features=1, out_features=5) # 5-dim lab type embedding
        self.lab_value = nn.Linear(in_features=1, out_features=5) # 5-dim lab value embedding
        self.layer_out = nn.Linear(in_features=10, out_features=5) # 5-dim lab output embedding
    
    def forward(self, x):
        x = torch.cat(x, dim=0) # dim = (batch_size, max_seq_len, 2)
        x_type = x[:, :, 0].unsqueeze(2)
        x_value = x[:, :, 1].unsqueeze(2)
        out = torch.cat((self.lab_type(x_type), self.lab_value(x_value)), dim=2)
        out = self.layer_out(out) # dim = (batch_size, max_seq_len, 5)
        return(out)

class PositionalEncoding(nn.Module):
    def __init__(self, d_model: int, dropout: float = 0.1, max_len: int = 5000):
        super().__init__()
        self.dropout = nn.Dropout(p=dropout)

        position = torch.arange(max_len).unsqueeze(1) # dim = (max_len, 1)
        div_term = torch.exp(torch.arange(0, d_model, 2) * (-math.log(10000.0) / d_model)) # dim = (d_model/2)
        pe = torch.zeros(max_len, 1, d_model) # dim = (max_len, 1, d_model)
        pe[:, 0, 0::2] = torch.sin(position * div_term)
        pe[:, 0, 1::2] = torch.cos(position * div_term)
        self.register_buffer('pe', pe)

    def forward(self, x: Tensor) -> Tensor:
        """
        Args:
            x: Tensor, shape [seq_len, batch_size, embedding_dim]
        """
        x = x + self.pe[:x.size(0)]
        return self.dropout(x)

class PatientEncounterModel(nn.Module):
    '''
    Patient encounter DL model structure.
    '''
    def __init__(
        self,
        d_model: int, # embedding dimension
        nhead: int, # number of heads in multi-head attention
        d_hid: int, # dimension of feedforward network model
        nlayers: int, # number of encoder layers
        dropout: float, # dropout probability
        embed_event_dim: int, # dimension of event embedding
        num_static_features: int, # number of static features
        num_lab_types: int, # number of lab types
        num_transformer_layers: 2, # number of transformer layers
        num_mlp_layers: int=2, # number of MLP layers
        num_mlp_features: int=11 # number of MLP features
        ):
        super().__init__()
        self.model_type = 'Transformer'
        self.pos_encoder = PositionalEncoding(d_model, dropout)
        encoder_layers = TransformerEncoderLayer(d_model, nhead, d_hid, dropout)
        self.transformer_encoder = TransformerEncoder(encoder_layers, nlayers)
        self.encoder = nn.Linear(embed_event_dim, d_model)
        self.d_model = d_model
        self.decoder = nn.Linear(d_model, embed_event_dim)
        self.lab_module = LabModule(num_lab_types=num_lab_types)
        self.layer_out = nn.Linear(in_features=num_static_features+d_model, out_features=10)
        self.fc1 = nn.Linear(in_features=10, out_features=10)
        self.fc2 = nn.Linear(in_features=10, out_features=10)
        self.fc3 = nn.Linear(in_features=10, out_features=1)
        self.sigmoid = nn.Sigmoid()
    
    def forward(self, x):
        out = self.lab_module(x[2]) # only lab-specific module for now
 
        # 4: feed modality-specific outputs into transformer architecture
        out = self.encoder(out) * math.sqrt(self.d_model)
        out = self.pos_encoder(out)
        out = self.transformer_encoder(out)
        out = torch.mean(out, dim=1, keepdim=True)

        # 5: concatenate outputs from transformer structure with static features
        out = torch.stack([out], dim=0).squeeze(0).squeeze(1)
        x_patient = torch.stack(x[0], dim=0).squeeze(2)
        x_encounter = torch.stack(x[1], dim=0).squeeze(1)
        out = torch.cat([x_patient, x_encounter, out], dim=1)

        # 6: feed concatenated output into MLP architecture
        out = self.layer_out(out)
        out = F.relu(self.fc1(out))
        out = F.relu(self.fc2(out))
        out = F.relu(self.fc3(out))
        out = self.sigmoid(out)

        return(out)

model = PatientEncounterModel(
    num_static_features=50, # number of static features
    num_transformer_layers=2, # number of transformer layers
    num_mlp_layers=2, # number of MLP layers
    num_mlp_features=11, # number of MLP features
    d_model=100, # embedding dimension
    nhead=2, # number of heads in multi-head attention
    d_hid=5, # dimension of feedforward network model
    nlayers=2, # number of encoder layers
    dropout=0.1, # dropout probability
    embed_event_dim=5 # dimension of event embedding
).to(device).double()
