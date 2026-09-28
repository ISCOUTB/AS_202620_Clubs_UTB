# settings.tf
resource "supabase_settings" "production" {
  project_ref = var.linked_project

  api = jsonencode({
    db_schema            = "public,graphql_public"
    db_extra_search_path = "public,extensions"
    max_rows             = 1000
  })

}