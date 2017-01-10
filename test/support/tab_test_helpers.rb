module TabTestHelpers
  def select_tab(tab_name)
    within "div.tabbable" do
      click_link tab_name
    end
  end
end
