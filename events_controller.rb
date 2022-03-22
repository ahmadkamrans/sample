# frozen_string_literal: true

class EventsController < ApplicationController

  # GET /events
  def index
    events = Event.active.non_training
    @search = events.includes(location: %i[country state]).joins(:location).ransack(params[:q])
    @events = @search.result(distinct: true).paginate(page: params[:page], per_page: 25)
  end
end