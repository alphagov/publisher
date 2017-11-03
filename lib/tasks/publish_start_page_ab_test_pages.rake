desc "Publish interstitial page"
task publish_interstitial_page: :environment do
  content_id = "4dc3b42e-4e96-4f66-b9d1-0cb5e9676e3c"
  params = {
    base_path: "/interstitial",
    document_type: "generic_with_external_related_links",
    locale: "en",
    public_updated_at: "2016-11-10T12:58:31.000+00:00",
    publishing_app: "publisher",
    rendering_app: "government-frontend",
    schema_name: "generic",
    update_type: "major",
    title: "Pick method",
    routes: [
      {
        path: "/interstitial",
        type: "exact"
      }
    ],
    description: "",
    details: {}
  }

  Services.publishing_api.put_content(content_id, params)
  Services.publishing_api.publish(content_id)
end
