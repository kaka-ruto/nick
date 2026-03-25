class Home::SettingsController < ApplicationController
  def show
    @user = Current.user
    @account = Current.account
  end
end
