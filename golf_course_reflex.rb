# frozen_string_literal: true

class GolfCourseReflex < ApplicationReflex
  include TeeSheetHelper
  
  before_reflex do
    @golf_course =policy_scope(GolfCourse).find_signed!(element.dataset.golf_course_signed_id)
    @golf_course.assign_attributes(golf_course_params) if golf_course_params
  end

  def edit
    html = render partial: 'settings/golf_courses/edit', locals: { golf_course: @golf_course }
    morph('#large-modal-content', html)
    cable_ready.dispatch_event(name: 'init_select2')
  end

  def update
    if @golf_course.save
      close_large_modal

      html = render partial: 'settings/golf_courses/row', locals: { golf_course: @golf_course }
      morph(dom_id(@golf_course, :row), html)

      flash(info: 'Course saved!')
    else
      flash(error: 'Unable to save course!')
    end
  end
end
