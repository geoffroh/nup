class IndexesController < ::ApplicationController
  skip_before_filter :verify_authenticity_token  
  def index
    render json: Index.all.map(&:attributes).sort_by{|i| i["version"].match(/\d+/)[0] }
  end

  def show
    render text: eval(Index.find(params[:id]).to_s)
  rescue StandardError => e
    render e
  end

  def create
    index = Index.shoehorn(params[:index])
    render text: index.to_s
  end
end
