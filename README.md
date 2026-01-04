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

## Deployment to k3s (Raspberry Pi)

The application is deployed to a k3s cluster on Raspberry Pi 5 with Cloudflare Tunnel for external access.

### Architecture

```
Internet -> Cloudflare -> Cloudflare Tunnel -> k3s Ingress -> Rails App -> PostgreSQL
                         (cloudflared pod)     (Traefik)      (job509)   (job509-postgres)
```

### Kubernetes Manifests

```
k8s/
├── deployment.yaml        # Rails app deployment + service + PVC
├── postgres.yaml          # PostgreSQL deployment + service + PVC
├── ingress.yaml           # Traefik ingress for job509.polym.at
├── secrets.yaml.example   # Template for secrets (copy and fill in)
├── github-actions-sa.yaml # Service account for CI/CD
├── CLOUDFLARE_SETUP.md    # Cloudflare tunnel instructions
└── README.md              # Detailed k8s setup docs
```

### Step 1: Create Secrets

```bash
# Copy the template
cp k8s/secrets.yaml.example k8s/secrets.yaml

# Edit with your values:
# - RAILS_MASTER_KEY: contents of config/master.key
# - POSTGRES_PASSWORD: generate a secure password
# - DATABASE_URL: postgres://job509:<password>@job509-postgres:5432/job509_production
# - SECRET_KEY_BASE: run `bin/rails secret`

# Apply to cluster
kubectl apply -f k8s/secrets.yaml
```

### Step 2: Create GHCR Pull Secret

```bash
kubectl create secret docker-registry ghcr-login-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=YOUR_EMAIL
```

### Step 3: Deploy PostgreSQL

```bash
kubectl apply -f k8s/postgres.yaml

# Wait for it to be ready
kubectl rollout status deployment/job509-postgres
```

### Step 4: Deploy the Application

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/ingress.yaml

# Wait for deployment
kubectl rollout status deployment/job509
```

### Step 5: Configure Cloudflare Tunnel

The Cloudflare Tunnel config is in the pistats project. Add the job509 route:

```bash
# In /Users/luc/code/personal/pistats/k8s/cloudfared-deployment.yaml
# The job509.polym.at route has already been added to the ConfigMap

# Apply the updated config
cd /Users/luc/code/personal/pistats
kubectl apply -f k8s/cloudfared-deployment.yaml
kubectl rollout restart deployment/cloudflared -n cloudflare
```

### Step 6: Add DNS Record in Cloudflare

```bash
# Using cloudflared CLI
cloudflared tunnel route dns aaa2e315-4ded-4ff5-a0e6-8d0965f02d42 job509.polym.at

# Or manually in Cloudflare Dashboard:
# Add CNAME: job509 -> aaa2e315-4ded-4ff5-a0e6-8d0965f02d42.cfargotunnel.com
```

### Step 7: Verify Deployment

```bash
# Check pods are running
kubectl get pods -l app=job509
kubectl get pods -l app=job509-postgres

# Check the health endpoint
curl https://job509.polym.at/up

# View logs
kubectl logs -f deployment/job509
```

### CI/CD with GitHub Actions

Pushing to `main` triggers automatic build and deployment:

1. **docker-build.yml** - Builds ARM64 image, pushes to GHCR
2. **deploy.yml** - Applies k8s manifests, restarts deployment

#### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `KUBECONFIG_DATA` | Base64-encoded kubeconfig with cluster access |

See `k8s/github-actions-sa.yaml` for service account setup.

### Useful Commands

```bash
# Rails console in cluster
kubectl exec -it deployment/job509 -- bin/rails console

# Database console
kubectl exec -it deployment/job509-postgres -- psql -U job509 job509_production

# Restart deployment
kubectl rollout restart deployment/job509

# View events
kubectl get events --sort-by='.lastTimestamp' | grep job509
```

### Resource Limits

Optimized for Raspberry Pi 5:

| Component | Memory (request/limit) | CPU (request/limit) |
|-----------|------------------------|---------------------|
| Rails App | 256Mi / 512Mi | 100m / 500m |
| PostgreSQL | 128Mi / 256Mi | 50m / 250m |

## License

Proprietary - All rights reserved.
