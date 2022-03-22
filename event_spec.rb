# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do

  context 'associations' do
    it 'has the following relationships', :aggregate_failures do
      should belong_to(:location)
    end
  end

  context 'validations' do
    it 'is valid', :aggregate_failures do
      is_expected.to validate_presence_of :name
      is_expected.to validate_presence_of :start_at
      is_expected.to validate_presence_of :end_at
      is_expected.to validate_presence_of :event_type
      is_expected.to validate_presence_of :publish_on
      expect(build_stubbed(:event, start_at: Date.yesterday)).not_to be_valid
      expect(
        build_stubbed(:event, start_at: Date.current, end_at: Date.yesterday)
      ).not_to be_valid
      expect(build_stubbed(:event, start_at: Time.current, end_at: Time.current)).to be_valid
    end
  end

end

# == Schema Information
#
# Table name: events
#
#  id(Primary key. Identity seed.)                                   :bigint           not null, primary key
#  description(The description of the event.)                        :text
#  end_at(The end_at value)                                          :datetime
#  event_type(list of the event types.)                              :integer
#  is_showcased(Flag to showcase the event on the homepage or not.)  :boolean
#  name(The title of the event.)                                     :string
#  publish_on(The date to publish the event.)                        :date
#  start_at(The date of the event.)                                  :datetime
#  url(The URL to more information about the event.)                 :string
#  created_at(Date/time row was inserted.)                           :datetime         not null
#  updated_at(Date/time row was last updated.)                       :datetime         not null
#  location_id(Foreign key constraint to the locations table PK(id)) :bigint
#
# Indexes
#
#  index_events_on_location_id  (location_id)
#