class ResumePdf
  include Prawn::View

  def initialize(resume)
    @resume = resume
    @user = resume.user
    generate_content
  end

  def document
    @document ||= Prawn::Document.new(
      page_size: "A4",
      margin: [40, 50, 40, 50]
    )
  end

  private

  def generate_content
    header
    contact_info
    objective_section if @resume.objective.present?
    summary_section
    education_section if @resume.educations.any?
    work_experience_section if @resume.work_experiences.any?
    skills_section if @resume.skills.any?
    languages_section if @resume.language_skills.any?
    references_section if @resume.referrals.any?
  end

  def header
    text @user.full_name, size: 24, style: :bold, align: :center
    move_down 5
  end

  def contact_info
    contact_parts = [@user.email]
    contact_parts << @user.phone if @user.phone.present?

    text contact_parts.join(" | "), align: :center, size: 10, color: "666666"

    if @resume.city || @resume.country
      location = [@resume.city&.name, @resume.country&.name].compact.join(", ")
      text location, align: :center, size: 10, color: "666666"
    end

    move_down 10
    stroke_horizontal_rule
    move_down 15
  end

  def objective_section
    section_header "OBJECTIVE"
    text @resume.objective, size: 10, leading: 4
    move_down 15
  end

  def summary_section
    section_header "SUMMARY"

    data = []
    data << ["Industry", @resume.sector.name] if @resume.sector
    data << ["Experience", "#{@resume.years_of_experience} years"] if @resume.years_of_experience
    data << ["Nationality", @resume.nationality.name] if @resume.nationality
    data << ["Driver's License", "Yes"] if @resume.has_drivers_license

    if data.any?
      table(data, width: bounds.width, cell_style: { borders: [], padding: [2, 5] }) do
        column(0).font_style = :bold
        column(0).width = 120
      end
    end

    move_down 15
  end

  def education_section
    section_header "EDUCATION"

    @resume.educations.each do |education|
      text education.diploma, style: :bold, size: 11
      text education.school, size: 10, color: "2563EB"

      details = []
      details << education.field_of_study if education.field_of_study.present?
      details << education.graduation_year if education.graduation_year.present?
      details << "(In Progress)" unless education.is_completed

      text details.join(" - "), size: 9, color: "666666" if details.any?
      move_down 8
    end

    move_down 10
  end

  def work_experience_section
    section_header "WORK EXPERIENCE"

    @resume.work_experiences.each do |experience|
      # Title and date on same line
      text_box experience.title, at: [0, cursor], width: bounds.width - 150, style: :bold, size: 11
      text_box date_range(experience), at: [bounds.width - 150, cursor], width: 150, align: :right, size: 10, color: "666666"
      move_down 15

      text experience.company, size: 10, color: "2563EB"

      if experience.description.present?
        move_down 3
        text experience.description, size: 9, leading: 3
      end

      move_down 10
    end

    move_down 5
  end

  def skills_section
    section_header "SKILLS"
    text @resume.skills.map(&:description).join(" | "), size: 10
    move_down 15
  end

  def languages_section
    section_header "LANGUAGES"

    @resume.language_skills.each do |ls|
      text "#{ls.language.name}: Speaking - #{ls.speaking_level.humanize}, Writing - #{ls.writing_level.humanize}", size: 10
      move_down 3
    end

    move_down 10
  end

  def references_section
    section_header "REFERENCES"

    @resume.referrals.each_slice(2) do |referral_pair|
      bounding_box([0, cursor], width: bounds.width) do
        referral_pair.each_with_index do |referral, idx|
          bounding_box([idx * (bounds.width / 2), bounds.top], width: bounds.width / 2 - 10) do
            text "#{referral.firstname} #{referral.lastname}", style: :bold, size: 10
            text referral.relationship, size: 9, color: "666666"
            text referral.phone, size: 9 if referral.phone.present?
            text referral.email, size: 9 if referral.email.present?
          end
        end
      end
      move_down 10
    end
  end

  def section_header(title)
    text title, size: 12, style: :bold
    move_down 2
    stroke do
      stroke_color "CCCCCC"
      horizontal_line 0, bounds.width
    end
    move_down 8
  end

  def date_range(experience)
    start_date = [experience.starting_month, experience.starting_year].compact.join("/")
    end_date = if experience.is_current
      "Present"
    else
      [experience.ending_month, experience.ending_year].compact.join("/")
    end
    "#{start_date} - #{end_date}"
  end
end
