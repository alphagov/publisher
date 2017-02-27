class SearchIndexPresenter < SimpleDelegator
  def state
    case __getobj__.state
    when 'published' then 'live'
    when 'archived' then 'archived'
    else 'draft'
    end
  end

  def description
    overview
  end

  def paths
    if exact_route?
      ["/#{slug}", "/#{slug}.json"]
    else
      ["/#{slug}.json"]
    end
  end

  def prefixes
    if exact_route?
      []
    else
      ["/#{slug}"]
    end
  end

  def public_timestamp
    public_updated_at
  end
end
