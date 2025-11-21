terraform {
  # Definisci i provider necessari e le loro versioni
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configurazione del Backend (S3 + DynamoDB) per la gestione remota e sicura dello stato
  # Modifica i valori 'bucket' e 'dynamodb_table' con i tuoi nomi reali
  backend "s3" {
    bucket         = "terraform" 
    key            = "terraform.tfstate"
    region         = "eu-south-1"                  
    encrypt        = true                          
  }
}

provider "aws" {
  region = "eu-south-1" 

  default_tags {
    tags = {
      project    = "sandbox"
      terraform   = "true"
    }
  }
}