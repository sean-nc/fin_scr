class StaticPagesController < ApplicationController
  def home
  end

  def profiles
    @profiles = Profile.all
  end

  def search
    SearchService.run()
  end
end
