class SkyscannerApiController < ApplicationController
  def demo
  end

  def cheapest_quotes
  	respond_to do |format|
  		format.json { render json: SkyscannerApi.cheapest_quotes(params[:origin_place], params[:destination_place], params[:outbound_date], params[:inbound_date]) }
  	end
  end

  def creating_the_session
  	respond_to do |format|
  		format.json { render json: { 'SessionKey' => SkyscannerApi.creating_the_session(params[:origin_place], params[:destination_place], params[:outbound_date], params[:inbound_date]) } }
  	end
  end
end
