class StaticPagesController < ApplicationController
  def home
  end

  def profiles
    @profiles = Profile.search(params[:query])

    respond_to do |format|
      format.html { @profiles = @profiles.paginate(:page => params[:page], :per_page => 10) }
      format.xlsx
    end
  end

  def search
    SearchService.run
  end
end
