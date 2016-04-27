class PanopticonReregisterer < WorkerBase
  def call(edition_id)
    edition = Edition.find(edition_id)
    edition.register_with_panopticon
  end
end
