module SystemTestHelper
  include ActionView::Helpers::JavaScriptHelper

  def sign_in(email_address, password = "secret123456")
    visit new_session_url

    fill_in "email_address", with: email_address
    fill_in "password", with: password

    click_on "log_in"
  end

  def fill_house_editor(name, content)
    execute_script <<~JS
      const editor = document.querySelector("[name='#{name}']")
      editor.value = "#{escape_javascript(content)}"
    JS
  end
end
