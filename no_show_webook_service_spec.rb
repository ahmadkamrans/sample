require 'rails_helper'

RSpec.describe Webhook::NoShowService do
  subject(:result) { described_class.call(slot: slot, charge: charge) }

  let!(:season) { create :season, :all_year, golf_course: golf_course }
  let!(:time_frame) { create :time_frame, :all_day, :every_day, season: season }
  let(:golf_course) { create :golf_course }
  let(:reservation) { create :reservation, golf_course: golf_course, owner: golfer }
  let(:slot) { reservation.slots.first }
  let(:charge) { true }
  let(:golfer) { create :golfer }

  describe '.call' do
    context 'With a slot with a non-golfpay golfer' do
      it { expect(result).to be_a_success }
      it { expect{result}.not_to have_enqueued_job(Webhook::DeliveryJob) }
    end

    context 'With a slot with a golfpay golfer' do
      let(:golfer) { create :golfer, golfpay_identifier: "123" }

      context 'Without any registered webhooks' do
        it { expect(result).to be_a_success }
        it { expect{result}.not_to have_enqueued_job(Webhook::DeliveryJob) }
      end

      context 'With one registered webhook for no_show' do
        let!(:endpoint) { create :webhook_endpoint, events: [:no_show] }
        it "succeeds and enqueues a delivery" do
          expect(Webhook::Endpoint.enabled.for_event('no_show').count).to eq 1
          expect{
            expect(result).to be_a_success
          }.to have_enqueued_job(Webhook::DeliveryJob)
        end
      end
    end
  end
end
