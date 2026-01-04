# job509.com

A rewrite of job509.com in Ruby on Rails 8.1.1 with PostgreSQL, Devise authentication, and TailwindCSS.

## Requirements

- Ruby 3.3+
- PostgreSQL 14+
- Node.js 18+ (for TailwindCSS)

## Getting Started

### Quick Setup

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Start the server
bin/dev
```

Visit http://localhost:3000 to see the application.

### Project Structure

```
app/
├── controllers/
│   ├── lakay/              # Admin panel controllers
│   ├── api/                # JSON API controllers
│   ├── jobs_controller.rb  # Public job listings
│   ├── resumes_controller.rb
│   └── ...
├── models/
│   ├── user.rb             # Job seekers & employers (Devise)
│   ├── administrator.rb    # Admin users (separate auth)
│   ├── job.rb              # Job postings
│   ├── resume.rb           # Job seeker resumes
│   └── ...
├── views/
│   ├── layouts/
│   │   ├── application.html.erb  # Public layout
│   │   └── admin.html.erb        # Admin panel layout
│   ├── lakay/              # Admin views
│   └── ...
└── assets/
    └── stylesheets/
        └── application.tailwind.css
```

### Key Concepts

**User Roles**
- `job_seeker` - Can create resumes, apply to jobs
- `employer` - Can post jobs, view applicants

**Authentication**
- Public users: Devise (`/login`, `/signup`)
- Administrators: Separate auth (`/lakay/login`)

**Namespaces**
- `/` - Public job board
- `/lakay` - Admin panel (Haitian Creole for "home")
- `/api` - JSON API endpoints

### Creating Test Data

```bash
bin/rails console

# Create a job seeker
user = User.create!(
  email: 'seeker@example.com',
  password: 'password123',
  firstname: 'Jean',
  lastname: 'Baptiste',
  role: :job_seeker
)

# Create an employer
employer = User.create!(
  email: 'employer@example.com',
  password: 'password123',
  firstname: 'Marie',
  lastname: 'Pierre',
  role: :employer
)

# Create an admin
admin = Administrator.create!(
  name: 'admin',
  password: 'admin123',
  role: :super
)

# Create lookup data
Country.create!(name: 'Haiti')
City.create!(name: 'Port-au-Prince', country: Country.first)
Sector.create!(name: 'Technology')
Jobtype.create!(name: 'Full-time')
```

### Running Tests

```bash
bin/rails test
bin/rails test:system
```

### Useful Commands

```bash
# View all routes
bin/rails routes

# Rails console
bin/rails console

# Database console
bin/rails dbconsole

# Generate a new controller
bin/rails generate controller ControllerName action1 action2

# Run migrations
bin/rails db:migrate
```

## Migrating from Legacy MySQL Database

The legacy jobyola application runs on MySQL. Use these instructions to migrate data to the new PostgreSQL database.

### Prerequisites

- SSH access to the Rackspace server hosting MySQL
- MySQL credentials for the jobyola database
- Local PostgreSQL database created and migrated

### Option 1: Rake Task via SSH Tunnel (Recommended)

This approach uses Ruby to migrate data with full control over transformations.

**Terminal 1** - Create SSH tunnel (keep this running):
```bash
ssh -L 3307:localhost:3306 user@your-rackspace-server.com -N
```

**Terminal 2** - Run migration:
```bash
# Set environment variables
export MYSQL_HOST=127.0.0.1
export MYSQL_PORT=3307
export MYSQL_DATABASE=jobyola_production
export MYSQL_USERNAME=your_mysql_user
export MYSQL_PASSWORD=your_mysql_password

# Test connection first
bin/rails migrate:from_mysql:test_connection

# Run full migration
bin/rails migrate:from_mysql
```

#### Available Migration Tasks

| Task | Description |
|------|-------------|
| `migrate:from_mysql` | Run full migration (all tables) |
| `migrate:from_mysql:test_connection` | Test MySQL connection |
| `migrate:from_mysql:check_dependencies` | Verify PostgreSQL dependencies |
| `migrate:from_mysql:lookup_tables` | Migrate countries, cities, sectors, jobtypes, languages |
| `migrate:from_mysql:users` | Migrate users |
| `migrate:from_mysql:jobs` | Migrate jobs |
| `migrate:from_mysql:resumes` | Migrate resumes and components |
| `migrate:from_mysql:applications` | Migrate job applications |
| `migrate:from_mysql:events` | Migrate events and attendees |
| `migrate:from_mysql:admin` | Migrate tags, lists, coupons, etc. |

#### Migration Order (Dependency Chain)

The full migration runs in this order to satisfy foreign key dependencies:

1. **Lookup tables** - countries, cities, sectors, jobtypes, languages (no dependencies)
2. **Users** - no dependencies
3. **Jobs** - depends on users, jobtypes, sectors, countries, cities
4. **Resumes** - depends on users, sectors, countries, cities
5. **Resume components** - educations, work_experiences, skills, language_skills, referrals (depend on resumes)
6. **Applications** - depends on users and jobs
7. **Events** - no dependencies
8. **Attendees** - depends on events
9. **Admin data** - tags, taggings, lists, coupons, featured_recruiters, share_tokens

### Option 2: Shell Script Migration

For direct mysqldump-style migration:

```bash
export RACKSPACE_SSH_HOST=your-rackspace-server.com
export RACKSPACE_SSH_USER=your-ssh-user
export MYSQL_DATABASE=jobyola_production
export MYSQL_USER=your_mysql_user
export MYSQL_PASSWORD=your_mysql_password

bin/migrate_from_rackspace
```

### Option 3: pgloader (Advanced)

For large databases, pgloader is faster but creates its own schema:

```bash
# Install pgloader
brew install pgloader  # macOS

# Edit connection strings in lib/tasks/pgloader.load
# Then run:
pgloader lib/tasks/pgloader.load
```

### Post-Migration Steps

1. **Verify data integrity**:
   ```bash
   bin/rails console
   > User.count
   > Job.count
   > Resume.count
   ```

2. **Create administrator accounts** (passwords are cleared during migration):
   ```bash
   bin/rails console
   > Administrator.create!(name: 'admin', password: 'secure_password', role: :super)
   ```

3. **Users must reset passwords** - all user passwords are cleared during migration for security.

4. **Migrate file attachments** (if applicable) - Paperclip attachments need to be migrated to Active Storage separately.

## Admin Panel

Access the admin panel at `/lakay`:
- Login: `/lakay/login`
- Dashboard: `/lakay`

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/jobs` | List jobs (JSON) |
| `GET /api/companies` | Search companies |
| `GET /api/schools` | Search schools |
| `GET /api/sectors` | List sectors |
| `GET /api/cities` | Search cities |

## Deployment

The application is designed to run on a k3s cluster (Raspberry Pi 5).

```bash
# Build Docker image for ARM64
docker buildx build --platform linux/arm64 -t your-registry/job509:latest --push .

# Deploy to k3s
kubectl apply -f k8s/
```

## License

Proprietary - All rights reserved.
