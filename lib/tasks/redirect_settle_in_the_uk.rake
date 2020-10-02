require "csv"

namespace :settle_in_the_uk do
  desc "Unpublish settle_in_uk content item and redirect "
  task unpublish_and_redirect: [:environment] do
    settle_in_the_uk_content_id = "32d4d2c8-2f9c-406f-96e4-65222074642a"

    redirect_paths = CSV.read(Rails.root.join("lib/tasks/settle_in_the_uk_paths.csv"), headers: true)

    redirects = []

    redirect_paths.each do |redirect|
      redirects.push(
        {
          path: redirect["from"],
          type: "exact",
          destination: redirect["to"],
        },
      )
    end

    Services.publishing_api.unpublish(
      settle_in_the_uk_content_id,
      locale: "en",
      type: "redirect",
      redirects: redirects,
      discard_drafts: true,
    )
  end
end
