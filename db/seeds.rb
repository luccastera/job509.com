# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# ============================================
# Countries
# ============================================
puts "Creating countries..."
countries = [
  { name: "Haiti" },
  { name: "United States" },
  { name: "Canada" },
  { name: "France" },
  { name: "Dominican Republic" },
  { name: "Jamaica" },
  { name: "Bahamas" },
  { name: "Other" }
]

countries.each do |country_attrs|
  Country.find_or_create_by!(name: country_attrs[:name])
end

haiti = Country.find_by!(name: "Haiti")
usa = Country.find_by!(name: "United States")

# ============================================
# Cities (Haiti)
# ============================================
puts "Creating cities..."
haiti_cities = [
  { name: "Port-au-Prince", latitude: "18.5944", longitude: "-72.3074" },
  { name: "Carrefour", latitude: "18.5419", longitude: "-72.4011" },
  { name: "Delmas", latitude: "18.5472", longitude: "-72.3028" },
  { name: "Petion-Ville", latitude: "18.5125", longitude: "-72.2856" },
  { name: "Cap-Haitien", latitude: "19.7578", longitude: "-72.2044" },
  { name: "Gonaives", latitude: "19.4500", longitude: "-72.6833" },
  { name: "Les Cayes", latitude: "18.1942", longitude: "-73.7489" },
  { name: "Jacmel", latitude: "18.2342", longitude: "-72.5350" },
  { name: "Jeremie", latitude: "18.6500", longitude: "-74.1167" },
  { name: "Saint-Marc", latitude: "19.1167", longitude: "-72.7000" },
  { name: "Hinche", latitude: "19.1500", longitude: "-72.0167" },
  { name: "Fort-Liberte", latitude: "19.6667", longitude: "-71.8333" },
  { name: "Port-de-Paix", latitude: "19.9333", longitude: "-72.8333" },
  { name: "Mirebalais", latitude: "18.8333", longitude: "-72.1000" },
  { name: "Leogane", latitude: "18.5111", longitude: "-72.6333" }
]

haiti_cities.each do |city_attrs|
  City.find_or_create_by!(name: city_attrs[:name], country: haiti) do |city|
    city.latitude = city_attrs[:latitude]
    city.longitude = city_attrs[:longitude]
  end
end

# USA cities
usa_cities = [
  { name: "Miami" },
  { name: "New York" },
  { name: "Boston" },
  { name: "Orlando" },
  { name: "Atlanta" },
  { name: "Washington DC" },
  { name: "Chicago" },
  { name: "Los Angeles" }
]

usa_cities.each do |city_attrs|
  City.find_or_create_by!(name: city_attrs[:name], country: usa)
end

# ============================================
# Job Types
# ============================================
puts "Creating job types..."
jobtypes = [
  "Full-time",
  "Part-time",
  "Contract",
  "Temporary",
  "Internship",
  "Volunteer",
  "Remote"
]

jobtypes.each do |name|
  Jobtype.find_or_create_by!(name: name)
end

# ============================================
# Sectors
# ============================================
puts "Creating sectors..."
sectors = [
  "Accounting / Finance",
  "Administration / Office",
  "Agriculture",
  "Architecture / Design",
  "Arts / Entertainment",
  "Banking",
  "Business Development",
  "Communications / PR",
  "Construction",
  "Consulting",
  "Customer Service",
  "Education / Training",
  "Engineering",
  "Environment",
  "Healthcare / Medical",
  "Hospitality / Tourism",
  "Human Resources",
  "Information Technology",
  "Insurance",
  "Legal",
  "Logistics / Supply Chain",
  "Manufacturing",
  "Marketing / Advertising",
  "Media / Journalism",
  "NGO / Non-Profit",
  "Real Estate",
  "Retail / Sales",
  "Security",
  "Social Services",
  "Telecommunications",
  "Transportation",
  "Other"
]

sectors.each do |name|
  Sector.find_or_create_by!(name: name)
end

# ============================================
# Languages
# ============================================
puts "Creating languages..."
languages = [
  "French",
  "Haitian Creole",
  "English",
  "Spanish",
  "Portuguese",
  "German",
  "Italian",
  "Chinese",
  "Arabic",
  "Japanese"
]

languages.each do |name|
  Language.find_or_create_by!(name: name)
end

# ============================================
# Default Administrator
# ============================================
puts "Creating default administrator..."
Administrator.find_or_create_by!(name: "admin") do |admin|
  admin.password = "admin123"
  admin.role = :super_admin
end

puts "Default admin credentials: admin / admin123"

# ============================================
# Sample Data (Development Only)
# ============================================
if Rails.env.development?
  puts "Creating sample data for development..."

  # Sample Employer
  employer = User.find_or_create_by!(email: "employer@example.com") do |user|
    user.password = "password123"
    user.firstname = "Jean"
    user.lastname = "Dupont"
    user.phone = "50937001234"
    user.role = :employer
  end

  # Sample Job Seeker
  job_seeker = User.find_or_create_by!(email: "jobseeker@example.com") do |user|
    user.password = "password123"
    user.firstname = "Marie"
    user.lastname = "Pierre"
    user.phone = "50937005678"
    user.role = :job_seeker
  end

  # Sample Jobs
  it_sector = Sector.find_by!(name: "Information Technology")
  fulltime = Jobtype.find_by!(name: "Full-time")
  pap = City.find_by!(name: "Port-au-Prince")

  5.times do |i|
    Job.find_or_create_by!(title: "Software Developer #{i + 1}", company: "Tech Haiti", user: employer) do |job|
      job.description = "We are looking for a talented software developer to join our team. You will work on exciting projects using modern technologies."
      job.qualifications = "- Bachelor's degree in Computer Science\n- 2+ years of experience\n- Proficiency in Ruby, Python, or JavaScript"
      job.company_description = "Tech Haiti is a leading technology company in Haiti, building innovative solutions for local and international clients."
      job.sector = it_sector
      job.jobtype = fulltime
      job.country = haiti
      job.city = pap
      job.post_date = Date.current - rand(0..30).days
      job.approved = [true, true, true, false].sample
    end
  end

  # Sample Resume for Job Seeker
  if job_seeker.resume.nil?
    resume = Resume.create!(
      user: job_seeker,
      objective: "Seeking a challenging position in the IT field where I can apply my skills and grow professionally.",
      sex: "F",
      birth_year: "1995",
      nationality: haiti,
      sector: it_sector,
      country: haiti,
      city: pap,
      years_of_experience: 3
    )

    resume.educations.create!(
      diploma: "Bachelor in Computer Science",
      school: "Universite d'Etat d'Haiti",
      graduation_year: "2018",
      field_of_study: "Computer Science",
      country: haiti,
      is_completed: true
    )

    resume.skills.create!(description: "Ruby on Rails")
    resume.skills.create!(description: "JavaScript")
    resume.skills.create!(description: "PostgreSQL")

    french = Language.find_by!(name: "French")
    english = Language.find_by!(name: "English")

    resume.language_skills.create!(language: french, speaking_level: :fluent, writing_level: :fluent)
    resume.language_skills.create!(language: english, speaking_level: :intermediate, writing_level: :intermediate)
  end

  puts "Sample users: employer@example.com / password123, jobseeker@example.com / password123"
end

puts "Seeding completed!"
