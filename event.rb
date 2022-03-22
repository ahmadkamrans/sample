# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :location, optional: true

  accepts_nested_attributes_for :location

  validates :name, :event_type, :publish_on, :start_at, :end_at, presence: true
  validates :start_at, timeliness: { on_or_after: :today, type: :datetime, allow_blank: false }
  validates :end_at, timeliness: { on_or_after: :start_at, type: :datetime, allow_blank: false }
  validates :url, url: true

  scope :active, lambda { |limit = nil, type = nil|
    scope = where(
      arel_table[:publish_on].lteq(Time.current.to_date).and(arel_table[:start_at].gteq(Time.current.to_date))
    )
    scope = scope.where(event_type: type) unless type.blank?
    scope = scope.limit(limit) unless limit.blank?
    scope
  }

  scope :non_training, -> { where.not(event_type: 3) }
  scope :non_published, -> { where(arel_table[:publish_on].gt(Time.current.to_date)) }
  scope :expired, -> { where(arel_table[:end_at].lt(Time.current.to_date)) }
  scope :showcased, -> { where(is_showcased: true) }
  scope :this_week, -> { where(arel_table[:start_at].lt(Time.current.to_date + 7.days)) }
  scope :from_month, lambda { |desired_month, desired_year|
    where('extract(month from start_at) = ? AND extract(year from start_at) = ?', desired_month, desired_year)
  }
  scope :on_or_after_date, ->(date) { where(arel_table[:start_at].gteq(date)) }

  enum event_type: { job_fair: 1, workshop: 2, training: 3 }

  def self.ransackable_scopes(_auth_object = nil)
    %i[active expired]
  end

  def published?
    publish_on <= Time.current.to_date
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