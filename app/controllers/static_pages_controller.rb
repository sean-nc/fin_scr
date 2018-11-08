class StaticPagesController < ApplicationController
  def about
  end

  def profiles
    @profiles = Profile.search(params[:query])

    respond_to do |format|
      format.html { @profiles = @profiles.paginate(:page => params[:page], :per_page => 30) }
      format.xlsx
    end
  end

  def search
    @terms = SearchTerm.where(searched: false)
    SearchService.run
  end
end
