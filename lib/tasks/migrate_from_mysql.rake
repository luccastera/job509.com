# frozen_string_literal: true

# MySQL to PostgreSQL Migration Task
#
# Prerequisites:
# 1. MySQL server accessible (directly or via SSH tunnel)
# 2. Set environment variables:
#    - MYSQL_HOST (default: localhost - use 127.0.0.1 for SSH tunnel)
#    - MYSQL_PORT (default: 3306 - use tunneled port e.g., 3307)
#    - MYSQL_DATABASE (default: jobyola_production)
#    - MYSQL_USERNAME (default: root)
#    - MYSQL_PASSWORD (default: empty)
#
# For Rackspace via SSH tunnel:
#   Terminal 1: ssh -L 3307:localhost:3306 user@rackspace-server -N
#   Terminal 2: MYSQL_HOST=127.0.0.1 MYSQL_PORT=3307 bin/rails migrate:from_mysql
#
# Usage:
#   bin/rails migrate:from_mysql                    # Run full migration
#   bin/rails migrate:from_mysql:test_connection    # Test MySQL connection
#   bin/rails migrate:from_mysql:check_dependencies # Verify dependency order
#   bin/rails migrate:from_mysql:lookup_tables      # Migrate only lookup tables
#   bin/rails migrate:from_mysql:users              # Migrate only users
#   bin/rails migrate:from_mysql:jobs               # Migrate only jobs
#   bin/rails migrate:from_mysql:resumes            # Migrate only resumes
#   bin/rails migrate:from_mysql:applications       # Migrate only applications
#   bin/rails migrate:from_mysql:events             # Migrate only events
#   bin/rails migrate:from_mysql:admin              # Migrate only admin data
#
# Dependency Order (automatically enforced):
#   1. Lookup tables: countries, cities, sectors, jobtypes, languages
#   2. Users (no dependencies)
#   3. Jobs (depends on: users, jobtypes, sectors, countries, cities)
#   4. Resumes (depends on: users, sectors, countries, cities)
#   5. Resume components (depends on: resumes, languages)
#   6. Applications (depends on: users, jobs)
#   7. Events (no dependencies)
#   8. Attendees (depends on: events)
#   9. Admin data: tags, taggings, lists, coupons, etc.

require "mysql2"

namespace :migrate do
  namespace :from_mysql do
    def mysql_client
      @mysql_client ||= Mysql2::Client.new(
        host: ENV.fetch("MYSQL_HOST", "localhost"),
        port: ENV.fetch("MYSQL_PORT", 3306).to_i,
        database: ENV.fetch("MYSQL_DATABASE", "jobyola_production"),
        username: ENV.fetch("MYSQL_USERNAME", "root"),
        password: ENV.fetch("MYSQL_PASSWORD", ""),
        encoding: "utf8mb4",
        reconnect: true,
        read_timeout: 300,
        write_timeout: 300
      )
    end

    def log(message)
      puts "[#{Time.current.strftime('%H:%M:%S')}] #{message}"
    end

    def log_error(message)
      puts "[#{Time.current.strftime('%H:%M:%S')}] ERROR: #{message}"
    end

    def migrate_with_id_preservation(table_name)
      # Temporarily allow manual ID assignment
      ActiveRecord::Base.connection.execute("ALTER TABLE #{table_name} DISABLE TRIGGER ALL") if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      yield
      ActiveRecord::Base.connection.execute("ALTER TABLE #{table_name} ENABLE TRIGGER ALL") if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"

      # Reset sequence to max ID + 1
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        max_id = ActiveRecord::Base.connection.execute("SELECT MAX(id) FROM #{table_name}").first["max"].to_i
        ActiveRecord::Base.connection.execute("SELECT setval('#{table_name}_id_seq', #{max_id + 1}, false)")
      end
    end

    # =========================================
    # Connection Test
    # =========================================
    desc "Test MySQL connection"
    task test_connection: :environment do
      log "Testing MySQL connection..."
      log "  Host: #{ENV.fetch('MYSQL_HOST', 'localhost')}"
      log "  Port: #{ENV.fetch('MYSQL_PORT', 3306)}"
      log "  Database: #{ENV.fetch('MYSQL_DATABASE', 'jobyola_production')}"
      log "  Username: #{ENV.fetch('MYSQL_USERNAME', 'root')}"

      begin
        result = mysql_client.query("SELECT COUNT(*) as count FROM users")
        count = result.first["count"]
        log "Connection successful! Found #{count} users in MySQL."

        # Show table counts
        log ""
        log "MySQL table counts:"
        %w[countries cities sectors jobtypes languages users jobs resumes
           educations work_experiences skills language_skills referrals
           applics events attendees tags taggings lists coupons].each do |table|
          begin
            result = mysql_client.query("SELECT COUNT(*) as count FROM #{table}")
            log "  #{table}: #{result.first['count']}"
          rescue => e
            log "  #{table}: (table not found)"
          end
        end
      rescue => e
        log_error "Connection failed: #{e.message}"
        log ""
        log "If using SSH tunnel, make sure it's running:"
        log "  ssh -L 3307:localhost:3306 user@rackspace-server -N"
        log ""
        log "Then set environment variables:"
        log "  export MYSQL_HOST=127.0.0.1"
        log "  export MYSQL_PORT=3307"
        exit 1
      end
    end

    # =========================================
    # Dependency Check
    # =========================================
    desc "Check PostgreSQL tables have required dependencies"
    task check_dependencies: :environment do
      log "Checking PostgreSQL table dependencies..."

      checks = {
        "jobs" => { requires: %w[users jobtypes sectors countries], table: Job },
        "resumes" => { requires: %w[users], table: Resume },
        "educations" => { requires: %w[resumes], table: Education },
        "work_experiences" => { requires: %w[resumes], table: WorkExperience },
        "skills" => { requires: %w[resumes], table: Skill },
        "language_skills" => { requires: %w[resumes languages], table: LanguageSkill },
        "referrals" => { requires: %w[resumes], table: Referral },
        "applics" => { requires: %w[users jobs], table: Applic },
        "attendees" => { requires: %w[events], table: Attendee },
        "taggings" => { requires: %w[tags users], table: Tagging }
      }

      all_good = true

      checks.each do |table, config|
        config[:requires].each do |dep|
          count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{dep}").first["count"].to_i
          if count == 0
            log_error "#{table} requires #{dep}, but #{dep} is empty!"
            all_good = false
          else
            log "  #{table} <- #{dep}: OK (#{count} records)"
          end
        end
      end

      if all_good
        log ""
        log "All dependencies satisfied!"
      else
        log ""
        log_error "Some dependencies are missing. Run migrations in order:"
        log "  1. bin/rails migrate:from_mysql:lookup_tables"
        log "  2. bin/rails migrate:from_mysql:users"
        log "  3. bin/rails migrate:from_mysql:jobs"
        log "  4. bin/rails migrate:from_mysql:resumes"
        log "  5. bin/rails migrate:from_mysql:applications"
        log "  6. bin/rails migrate:from_mysql:events"
        log "  7. bin/rails migrate:from_mysql:admin"
      end
    end

    # =========================================
    # Lookup Tables
    # =========================================
    desc "Migrate lookup tables (countries, cities, sectors, jobtypes, languages)"
    task lookup_tables: :environment do
      log "Starting lookup tables migration..."

      # Countries
      log "Migrating countries..."
      countries = mysql_client.query("SELECT * FROM countries ORDER BY id")
      migrate_with_id_preservation("countries") do
        countries.each do |row|
          Country.find_or_create_by!(id: row["id"]) do |c|
            c.name = row["name"]
            c.created_at = row["created_at"] || Time.current
            c.updated_at = row["updated_at"] || Time.current
          end
        end
      end
      log "  Migrated #{countries.count} countries"

      # Cities
      log "Migrating cities..."
      cities = mysql_client.query("SELECT * FROM cities ORDER BY id")
      migrate_with_id_preservation("cities") do
        cities.each do |row|
          City.find_or_create_by!(id: row["id"]) do |c|
            c.name = row["name"]
            c.country_id = row["country_id"]
            c.latitude = row["latitude"]
            c.longitude = row["longitude"]
            c.created_at = row["created_at"] || Time.current
            c.updated_at = row["updated_at"] || Time.current
          end
        end
      end
      log "  Migrated #{cities.count} cities"

      # Sectors
      log "Migrating sectors..."
      sectors = mysql_client.query("SELECT * FROM sectors ORDER BY id")
      migrate_with_id_preservation("sectors") do
        sectors.each do |row|
          Sector.find_or_create_by!(id: row["id"]) do |s|
            s.name = row["name"]
            s.created_at = row["created_at"] || Time.current
            s.updated_at = row["updated_at"] || Time.current
          end
        end
      end
      log "  Migrated #{sectors.count} sectors"

      # Jobtypes
      log "Migrating jobtypes..."
      jobtypes = mysql_client.query("SELECT * FROM jobtypes ORDER BY id")
      migrate_with_id_preservation("jobtypes") do
        jobtypes.each do |row|
          Jobtype.find_or_create_by!(id: row["id"]) do |j|
            j.name = row["name"]
            j.created_at = row["created_at"] || Time.current
            j.updated_at = row["updated_at"] || Time.current
          end
        end
      end
      log "  Migrated #{jobtypes.count} jobtypes"

      # Languages
      log "Migrating languages..."
      languages = mysql_client.query("SELECT * FROM languages ORDER BY id")
      migrate_with_id_preservation("languages") do
        languages.each do |row|
          Language.find_or_create_by!(id: row["id"]) do |l|
            l.name = row["name"]
            l.created_at = row["created_at"] || Time.current
            l.updated_at = row["updated_at"] || Time.current
          end
        end
      end
      log "  Migrated #{languages.count} languages"

      log "Lookup tables migration completed!"
    end

    # =========================================
    # Users
    # =========================================
    desc "Migrate users"
    task users: :environment do
      log "Starting users migration..."

      users = mysql_client.query("SELECT * FROM users ORDER BY id")
      migrated = 0
      skipped = 0

      migrate_with_id_preservation("users") do
        users.each do |row|
          # Skip users with invalid emails
          if row["email"].blank? || !row["email"].include?("@")
            skipped += 1
            next
          end

          # Skip if user already exists
          if User.exists?(id: row["id"])
            skipped += 1
            next
          end

          begin
            user = User.new(
              id: row["id"],
              email: row["email"].downcase.strip,
              firstname: row["firstname"],
              lastname: row["lastname"],
              phone: row["phone"],
              alternate_phone: row["alternate_phone"],
              role: row["role"] == "employer" ? :employer : :job_seeker,
              job509_comments: row["job509_comments"],
              created_at: row["created_at"] || Time.current,
              updated_at: row["updated_at"] || Time.current,
              # Set a random password - users will need to reset
              password: SecureRandom.hex(16),
              # Store reset code if exists
              reset_password_token: row["reset_password_code"].present? ? Devise.token_generator.digest(User, :reset_password_token, row["reset_password_code"]) : nil
            )
            user.save!(validate: false)
            migrated += 1
          rescue => e
            log "  Error migrating user #{row['id']} (#{row['email']}): #{e.message}"
            skipped += 1
          end
        end
      end

      log "Users migration completed! Migrated: #{migrated}, Skipped: #{skipped}"
    end

    # =========================================
    # Jobs
    # =========================================
    desc "Migrate jobs"
    task jobs: :environment do
      log "Starting jobs migration..."

      jobs = mysql_client.query("SELECT * FROM jobs ORDER BY id")
      migrated = 0
      skipped = 0

      migrate_with_id_preservation("jobs") do
        jobs.each do |row|
          # Skip if job already exists
          if Job.exists?(id: row["id"])
            skipped += 1
            next
          end

          # Skip if user doesn't exist
          unless User.exists?(id: row["user_id"])
            log "  Skipping job #{row['id']}: user #{row['user_id']} not found"
            skipped += 1
            next
          end

          begin
            job = Job.new(
              id: row["id"],
              title: row["title"] || "Untitled",
              company: row["company"] || "Unknown",
              company_url: row["company_url"],
              company_description: row["company_description"],
              description: row["description"] || "No description",
              qualifications: row["qualifications"] || "Not specified",
              user_id: row["user_id"],
              jobtype_id: row["jobtype_id"] || Jobtype.first&.id,
              sector_id: row["sector_id"] || Sector.first&.id,
              country_id: row["country_id"] || Country.first&.id,
              city_id: row["city_id"],
              approved: row["approved"] || false,
              expired: row["expired"] || false,
              post_date: row["post_date"] || row["created_at"]&.to_date || Date.current,
              apply_url: row["apply_url"],
              payment_amount: row["payment_amount"],
              payment_type: row["payment_type"],
              payment_date: row["payment_date"],
              payment_comment: row["payment_comment"],
              created_at: row["created_at"] || Time.current,
              updated_at: row["updated_at"] || Time.current
            )
            job.save!(validate: false)
            migrated += 1
          rescue => e
            log "  Error migrating job #{row['id']}: #{e.message}"
            skipped += 1
          end
        end
      end

      log "Jobs migration completed! Migrated: #{migrated}, Skipped: #{skipped}"
    end

    # =========================================
    # Resumes and Components
    # =========================================
    desc "Migrate resumes and all components"
    task resumes: :environment do
      log "Starting resumes migration..."

      # Resumes
      resumes = mysql_client.query("SELECT * FROM resumes ORDER BY id")
      migrated = 0
      skipped = 0

      migrate_with_id_preservation("resumes") do
        resumes.each do |row|
          if Resume.exists?(id: row["id"])
            skipped += 1
            next
          end

          unless User.exists?(id: row["user_id"])
            skipped += 1
            next
          end

          begin
            resume = Resume.new(
              id: row["id"],
              user_id: row["user_id"],
              objective: row["objective"],
              sex: row["sex"],
              birth_year: row["birth_year"].to_i > 0 ? row["birth_year"].to_i : nil,
              nationality_id: row["nationality_id"],
              sector_id: row["sector_id"],
              has_drivers_license: row["has_drivers_license"],
              address1: row["address1"],
              address2: row["address2"],
              city_id: row["city_id"],
              country_id: row["country_id"],
              postal_code: row["postal_code"],
              years_of_experience: row["years_of_experience"],
              is_recommended: row["is_recommended"] || false,
              created_at: row["created_at"] || Time.current,
              updated_at: row["updated_at"] || Time.current
            )
            resume.save!(validate: false)
            migrated += 1
          rescue => e
            log "  Error migrating resume #{row['id']}: #{e.message}"
            skipped += 1
          end
        end
      end
      log "  Migrated #{migrated} resumes, skipped #{skipped}"

      # Educations
      log "Migrating educations..."
      educations = mysql_client.query("SELECT * FROM educations ORDER BY id")
      edu_count = 0
      migrate_with_id_preservation("educations") do
        educations.each do |row|
          next if Education.exists?(id: row["id"])
          next unless Resume.exists?(id: row["resume_id"])

          Education.create!(
            id: row["id"],
            resume_id: row["resume_id"],
            diploma: row["diploma"],
            school: row["school"],
            graduation_year: row["graduation_year"].to_i > 0 ? row["graduation_year"].to_i : nil,
            field_of_study: row["field_of_study"],
            is_completed: row["is_completed"],
            comments: row["comments"],
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          edu_count += 1
        rescue => e
          log "  Error migrating education #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{edu_count} educations"

      # Work Experiences
      log "Migrating work experiences..."
      work_exps = mysql_client.query("SELECT * FROM work_experiences ORDER BY id")
      work_count = 0
      migrate_with_id_preservation("work_experiences") do
        work_exps.each do |row|
          next if WorkExperience.exists?(id: row["id"])
          next unless Resume.exists?(id: row["resume_id"])

          WorkExperience.create!(
            id: row["id"],
            resume_id: row["resume_id"],
            company: row["company"],
            title: row["title"],
            description: row["description"],
            starting_month: row["starting_month"].to_i > 0 ? row["starting_month"].to_i : nil,
            starting_year: row["starting_year"].to_i > 0 ? row["starting_year"].to_i : nil,
            ending_month: row["ending_month"].to_i > 0 ? row["ending_month"].to_i : nil,
            ending_year: row["ending_year"].to_i > 0 ? row["ending_year"].to_i : nil,
            is_current: row["is_current"] || false,
            monthly_salary: row["monthly_salary"],
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          work_count += 1
        rescue => e
          log "  Error migrating work experience #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{work_count} work experiences"

      # Skills
      log "Migrating skills..."
      skills = mysql_client.query("SELECT * FROM skills ORDER BY id")
      skill_count = 0
      migrate_with_id_preservation("skills") do
        skills.each do |row|
          next if Skill.exists?(id: row["id"])
          next unless Resume.exists?(id: row["resume_id"])

          Skill.create!(
            id: row["id"],
            resume_id: row["resume_id"],
            description: row["description"],
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          skill_count += 1
        rescue => e
          log "  Error migrating skill #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{skill_count} skills"

      # Language Skills
      log "Migrating language skills..."
      lang_skills = mysql_client.query("SELECT * FROM language_skills ORDER BY id")
      lang_count = 0
      migrate_with_id_preservation("language_skills") do
        lang_skills.each do |row|
          next if LanguageSkill.exists?(id: row["id"])
          next unless Resume.exists?(id: row["resume_id"])
          next unless Language.exists?(id: row["language_id"])

          LanguageSkill.create!(
            id: row["id"],
            resume_id: row["resume_id"],
            language_id: row["language_id"],
            speaking_level: normalize_language_level(row["speaking_level"]),
            writing_level: normalize_language_level(row["writing_level"]),
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          lang_count += 1
        rescue => e
          log "  Error migrating language skill #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{lang_count} language skills"

      # Referrals
      log "Migrating referrals..."
      referrals = mysql_client.query("SELECT * FROM referrals ORDER BY id")
      ref_count = 0
      migrate_with_id_preservation("referrals") do
        referrals.each do |row|
          next if Referral.exists?(id: row["id"])
          next unless Resume.exists?(id: row["resume_id"])

          Referral.create!(
            id: row["id"],
            resume_id: row["resume_id"],
            firstname: row["firstname"],
            lastname: row["lastname"],
            phone: row["phone"],
            email: row["email"],
            relationship: row["relationship"],
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          ref_count += 1
        rescue => e
          log "  Error migrating referral #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{ref_count} referrals"

      log "Resumes migration completed!"
    end

    def normalize_language_level(level)
      case level.to_s.downcase
      when "basic", "beginner", "1"
        :basic
      when "intermediate", "conversational", "2"
        :intermediate
      when "fluent", "advanced", "native", "3"
        :fluent
      else
        :basic
      end
    end

    # =========================================
    # Applications
    # =========================================
    desc "Migrate applications (applics)"
    task applications: :environment do
      log "Starting applications migration..."

      applics = mysql_client.query("SELECT * FROM applics ORDER BY id")
      migrated = 0
      skipped = 0

      migrate_with_id_preservation("applics") do
        applics.each do |row|
          if Applic.exists?(id: row["id"])
            skipped += 1
            next
          end

          unless User.exists?(id: row["user_id"]) && Job.exists?(id: row["job_id"])
            skipped += 1
            next
          end

          begin
            Applic.create!(
              id: row["id"],
              user_id: row["user_id"],
              job_id: row["job_id"],
              cover_letter: row["cover_letter"],
              hidden: row["hidden"] || false,
              star: row["star"] || false,
              created_at: row["created_at"] || Time.current,
              updated_at: row["updated_at"] || Time.current
            )
            migrated += 1
          rescue => e
            log "  Error migrating application #{row['id']}: #{e.message}"
            skipped += 1
          end
        end
      end

      log "Applications migration completed! Migrated: #{migrated}, Skipped: #{skipped}"
    end

    # =========================================
    # Events
    # =========================================
    desc "Migrate events and attendees"
    task events: :environment do
      log "Starting events migration..."

      # Events
      events = mysql_client.query("SELECT * FROM events ORDER BY id")
      event_count = 0

      migrate_with_id_preservation("events") do
        events.each do |row|
          next if Event.exists?(id: row["id"])

          Event.create!(
            id: row["id"],
            name: row["name"] || "Untitled Event",
            description: row["description"],
            starts_at: row["starts_at"] || Time.current,
            ends_at: row["ends_at"] || Time.current + 2.hours,
            location: row["location"] || "TBD",
            youtube_url: row["youtube_url"],
            cost: row["cost"],
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          event_count += 1
        rescue => e
          log "  Error migrating event #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{event_count} events"

      # Attendees
      log "Migrating attendees..."
      attendees = mysql_client.query("SELECT * FROM attendees ORDER BY id")
      attendee_count = 0

      migrate_with_id_preservation("attendees") do
        attendees.each do |row|
          next if Attendee.exists?(id: row["id"])
          next unless Event.exists?(id: row["event_id"])

          Attendee.create!(
            id: row["id"],
            event_id: row["event_id"],
            firstname: row["firstname"],
            lastname: row["lastname"],
            company: row["company"],
            phone: row["phone"],
            email: row["email"],
            paid: row["paid"] || false,
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          attendee_count += 1
        rescue => e
          log "  Error migrating attendee #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{attendee_count} attendees"

      log "Events migration completed!"
    end

    # =========================================
    # Admin Data
    # =========================================
    desc "Migrate administrators, coupons, tags, lists"
    task admin: :environment do
      log "Starting admin data migration..."

      # Note: Administrators use different password hashing
      # We'll skip password migration - admins will need new passwords
      log "Skipping administrators (different password hashing) - create new admin accounts manually"

      # Coupons
      log "Migrating coupons..."
      coupons = mysql_client.query("SELECT * FROM coupons ORDER BY id")
      coupon_count = 0

      migrate_with_id_preservation("coupons") do
        coupons.each do |row|
          next if Coupon.exists?(id: row["id"])

          Coupon.create!(
            id: row["id"],
            code: row["code"],
            value: row["value"],
            comment: row["comment"],
            administrator_id: nil, # Don't link to admin since we're not migrating them
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          coupon_count += 1
        rescue => e
          log "  Error migrating coupon #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{coupon_count} coupons"

      # Tags
      log "Migrating tags..."
      tags = mysql_client.query("SELECT * FROM tags ORDER BY id")
      tag_count = 0

      migrate_with_id_preservation("tags") do
        tags.each do |row|
          next if Tag.exists?(id: row["id"])

          Tag.create!(
            id: row["id"],
            name: row["name"],
            description: row["description"],
            event_id: row["event_id"],
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          tag_count += 1
        rescue => e
          log "  Error migrating tag #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{tag_count} tags"

      # Taggings
      log "Migrating taggings..."
      taggings = mysql_client.query("SELECT * FROM taggings ORDER BY id")
      tagging_count = 0

      migrate_with_id_preservation("taggings") do
        taggings.each do |row|
          next if Tagging.exists?(id: row["id"])
          next unless Tag.exists?(id: row["tag_id"]) && User.exists?(id: row["user_id"])

          Tagging.create!(
            id: row["id"],
            tag_id: row["tag_id"],
            user_id: row["user_id"],
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          tagging_count += 1
        rescue => e
          log "  Error migrating tagging #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{tagging_count} taggings"

      # Lists
      log "Migrating lists..."
      lists = mysql_client.query("SELECT * FROM lists ORDER BY id")
      list_count = 0

      migrate_with_id_preservation("lists") do
        lists.each do |row|
          next if List.exists?(id: row["id"])

          List.create!(
            id: row["id"],
            name: row["name"],
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          list_count += 1
        rescue => e
          log "  Error migrating list #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{list_count} lists"

      # List Users (join table)
      log "Migrating list_users..."
      list_users = mysql_client.query("SELECT * FROM lists_users ORDER BY id")
      list_user_count = 0

      list_users.each do |row|
        next unless List.exists?(id: row["list_id"]) && User.exists?(id: row["user_id"])

        list = List.find(row["list_id"])
        user = User.find(row["user_id"])
        unless list.users.include?(user)
          list.users << user
          list_user_count += 1
        end
      rescue => e
        log "  Error migrating list_user: #{e.message}"
      end
      log "  Migrated #{list_user_count} list_users"

      # Featured Recruiters
      log "Migrating featured recruiters..."
      recruiters = mysql_client.query("SELECT * FROM featured_recruiters ORDER BY id")
      recruiter_count = 0

      migrate_with_id_preservation("featured_recruiters") do
        recruiters.each do |row|
          next if FeaturedRecruiter.exists?(id: row["id"])

          FeaturedRecruiter.create!(
            id: row["id"],
            name: row["name"],
            website_url: row["website_url"],
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          recruiter_count += 1
        rescue => e
          log "  Error migrating featured recruiter #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{recruiter_count} featured recruiters"

      # Share Tokens
      log "Migrating share tokens..."
      tokens = mysql_client.query("SELECT * FROM share_tokens ORDER BY id")
      token_count = 0

      migrate_with_id_preservation("share_tokens") do
        tokens.each do |row|
          next if ShareToken.exists?(id: row["id"])
          next unless Resume.exists?(id: row["resume_id"])

          ShareToken.create!(
            id: row["id"],
            resume_id: row["resume_id"],
            token: row["token"],
            expires_in: row["expires_in"],
            created_at: row["created_at"] || Time.current,
            updated_at: row["updated_at"] || Time.current
          )
          token_count += 1
        rescue => e
          log "  Error migrating share token #{row['id']}: #{e.message}"
        end
      end
      log "  Migrated #{token_count} share tokens"

      log "Admin data migration completed!"
    end

    # =========================================
    # Full Migration
    # =========================================
    desc "Run full migration from MySQL to PostgreSQL"
    task all: :environment do
      log "=" * 60
      log "Starting full MySQL to PostgreSQL migration"
      log "=" * 60

      start_time = Time.current

      Rake::Task["migrate:from_mysql:lookup_tables"].invoke
      Rake::Task["migrate:from_mysql:users"].invoke
      Rake::Task["migrate:from_mysql:jobs"].invoke
      Rake::Task["migrate:from_mysql:resumes"].invoke
      Rake::Task["migrate:from_mysql:applications"].invoke
      Rake::Task["migrate:from_mysql:events"].invoke
      Rake::Task["migrate:from_mysql:admin"].invoke

      elapsed = Time.current - start_time
      log "=" * 60
      log "Full migration completed in #{elapsed.round(2)} seconds!"
      log "=" * 60
      log ""
      log "IMPORTANT: Users will need to reset their passwords."
      log "Create new administrator accounts manually."
      log ""
      log "Next steps:"
      log "1. Verify data integrity"
      log "2. Migrate Paperclip attachments to Active Storage (if needed)"
      log "3. Test the application thoroughly"
    end
  end

  # Shortcut task
  desc "Run full migration from MySQL"
  task from_mysql: "from_mysql:all"
end
