GovukTest.configure

Capybara.register_driver :headless_chrome do |app|
  chrome_options = GovukTest.headless_chrome_selenium_options
  chrome_options.add_argument("--disable-web-security")
  chrome_options.add_argument("--window-size=1400,1400")
  chrome_options.add_argument('--incognito') # Use incognito mode to avoid user data directory conflicts

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    # capabilities: { acceptInsecureCerts: true },
    options: chrome_options,
    )
end
