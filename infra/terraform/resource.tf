# resource.tf
variable "linked_project" {
  type = string
}

import {
  to = supabase_project.production
  id = var.linked_project
}

resource "supabase_project" "production" {
  organization_id   = "wmnnfywpzwqacntsezfg"
  name              = "LinkClub"
  database_password = "placeholder"
  region            = "us-east-1"

  lifecycle {
    ignore_changes = [database_password]
  }
}