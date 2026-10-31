require "rails_helper"

RSpec.describe Support::AiRun, type: :model do
  it "has a valid factory" do
    expect(build(:ai_run)).to be_valid
  end

  it { is_expected.to belong_to(:ticket).class_name("Support::Ticket") }
  it { is_expected.to belong_to(:playbook).class_name("Support::AiPlaybook").optional }

  it "requires run_trigger, step and status" do
    run = described_class.new
    expect(run).not_to be_valid
    expect(run.errors.attribute_names).to include(:run_trigger, :step, :status)
  end

  it "rejects unknown enum values" do
    expect(build(:ai_run, step: :bogus)).not_to be_valid
  end

  it "defaults tool_calls and output" do
    run = create(:ai_run)
    expect(run.tool_calls).to eq([])
    expect(run.output).to eq({})
  end

  it "has a handle step with en and es labels" do
    expect(described_class.steps).to include("handle" => 4)
    expect(I18n.t("enums.ai_run.step.handle", locale: :en)).to eq("Investigation and reply")
    expect(I18n.t("enums.ai_run.step.handle", locale: :es)).to eq("Investigación y respuesta")
    expect(I18n.t("enums.ai_run.step.triage", locale: :en)).to eq("Classification")
    expect(I18n.t("enums.ai_run.step.triage", locale: :es)).to eq("Clasificación")
  end

  describe ".latest_output" do
    let(:ticket) { create(:ticket) }

    it "returns the newest succeeded output of the step with indifferent access" do
      create(:ai_run, ticket: ticket, step: :handle, output: {"findings" => "old"})
      create(:ai_run, ticket: ticket, step: :handle, output: {"findings" => "new"})
      create(:ai_run, ticket: ticket, step: :handle, status: :failed, output: {"findings" => "failed"})
      expect(ticket.ai_runs.latest_output(:handle)[:findings]).to eq("new")
    end

    it "is nil without a succeeded run or with empty output" do
      create(:ai_run, ticket: ticket, step: :triage, output: {})
      expect(ticket.ai_runs.latest_output(:triage)).to be_nil
      expect(ticket.ai_runs.latest_output(:handle)).to be_nil
    end
  end

  it "orders recent first" do
    ticket = create(:ticket)
    old = create(:ai_run, ticket: ticket, created_at: 2.days.ago)
    new = create(:ai_run, ticket: ticket)
    expect(described_class.recent).to eq([new, old])
  end

  it "limits recent runs when given a limit" do
    ticket = create(:ticket)
    create(:ai_run, ticket: ticket, created_at: 2.days.ago)
    new = create(:ai_run, ticket: ticket)
    expect(ticket.recent_ai_runs(1)).to eq([new])
  end

  it "is destroyed with its ticket and nullified with its playbook" do
    playbook = create(:ai_playbook)
    run = create(:ai_run, playbook: playbook)
    playbook.destroy!
    expect(run.reload.playbook_id).to be_nil
    run.ticket.destroy!
    expect(described_class.exists?(run.id)).to be(false)
  end
end
