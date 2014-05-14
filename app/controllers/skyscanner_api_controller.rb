class SkyscannerApiController < ApplicationController
  def demo
  end

  def location_autosuggest
    respond_to do |format|
      format.json { render json: SkyscannerApi.location_autosuggest(params['query']) }
    end
  end

  def cheapest_quotes
    p params
    # render json: 'success'
  	respond_to do |format|
  		format.json { render json: SkyscannerApi.cheapest_quotes(params[:origin_place], params[:destination_place], params[:outbound_date], params[:inbound_date]) }
  	end
  end

  def creating_the_session
  	respond_to do |format|
  		format.json { render json: { 'SessionKey' => SkyscannerApi.creating_the_session(params[:origin_place], params[:destination_place], params[:outbound_date], params[:inbound_date]) } }
  	end
  end

  def polling_the_session
    respond_to do |format|
      format.json { render json: SkyscannerApi.polling_the_session(params['SessionKey']) }
    end
  end

  def creating_booking_details
    respond_to do |format|
      format.json { render json: { 'IitineraryKey' => SkyscannerApi.creating_booking_details(params['SessionKey'], params['OutboundLegId'], params['InboundLegId']) } }
    end
  end

  def polling_booking_details
    respond_to do |format|
      format.json { render json: SkyscannerApi.polling_booking_details(params['SessionKey'], params['IitineraryKey']) }
    end
  end
end
