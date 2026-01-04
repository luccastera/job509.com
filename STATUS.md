# Job509.com Project Status

**Last Updated:** January 3, 2026

## Project Overview

This is a complete rewrite of **job509.com**, a Haitian job board originally built in Rails 2.3 (codenamed "jobyola"), into a modern Rails 8.1.1 application. The legacy app runs on MySQL on a Rackspace server. The new app uses PostgreSQL and will be deployed to a k3s cluster on Raspberry Pi 5.

### Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Rails 8.1.1 |
| Database | PostgreSQL |
| Authentication | Devise (users), custom (administrators) |
| CSS | TailwindCSS with dark mode support |
| JavaScript | Hotwire (Turbo + Stimulus) |
| Pagination | Pagy |
| PDF Generation | Prawn |
| Payments | PayPal Server SDK |
| SMS | Twilio |
| Deployment | k3s on Raspberry Pi 5 |
| Container Registry | GitHub Container Registry (GHCR) |
| External Access | Cloudflare Tunnel |

### Key URLs

- **Production (planned):** https://job509.polym.at (temporary), https://job509.com (future)
- **Admin Panel:** `/lakay` (Haitian Creole for "home")
- **Legacy App:** Rackspace server (MySQL)

---

## What's Been Completed

### Phase 1: Foundation (100%)
- [x] Rails 8.1.1 app created with PostgreSQL
- [x] Gemfile configured with all dependencies
- [x] TailwindCSS installed with custom color palette (job-blue, job-red)
- [x] I18n configured for French (default) and English
- [x] Database schema with all 25+ tables migrated

### Phase 2: Authentication (100%)
- [x] Devise configured for User model (job seekers & employers)
- [x] Custom registration flows (`/signup`, `/emp_signup`)
- [x] Password reset flow
- [x] Separate Administrator model with `has_secure_password`
- [x] Admin authentication at `/lakay/login`

### Phase 3: Core Features (100%)
- [x] Jobs CRUD with search/filter
- [x] Job application flow
- [x] Resume builder with all sections (education, experience, skills, languages, referrals)
- [x] PDF resume generation
- [x] Employer dashboard (posted jobs, applicants)
- [x] Job seeker dashboard (applications, resume)

### Phase 4: Admin Panel (100%)
- [x] Dashboard with statistics
- [x] Job management (approve/reject, CRUD)
- [x] Job seeker management (search, recommend, PDF, tags, lists)
- [x] Employer management
- [x] Applications management
- [x] Events management with image uploads
- [x] Coupons CRUD
- [x] Tags CRUD with user assignment
- [x] Lists CRUD with user assignment
- [x] Featured recruiters management
- [x] Administrator management
- [x] Dark mode support
- [x] Scrollable sidebar with custom scrollbar styling

### Phase 5: Additional Features (90%)
- [x] Events public listing and registration
- [x] Static pages (about, FAQ, contact, advertise)
- [x] API endpoints (`/api/jobs`, `/api/companies`, `/api/schools`, `/api/sectors`, `/api/cities`)
- [x] Legacy JSON endpoints (`/jobs.json`, `/companies.json`, `/schools.json`)
- [x] Sitemap XML generation
- [x] RSS feed for jobs
- [x] PayPal payment integration (needs testing)
- [ ] Twilio SMS integration (stubbed, not implemented)

### Phase 6: UI/UX (100%)
- [x] Public layout with TailwindCSS
- [x] Admin layout with sidebar navigation
- [x] Dark mode support throughout admin panel
- [x] Responsive design
- [x] Custom color palette applied

### Phase 7: Database Migration Tools (100%)
- [x] Rake task for MySQL to PostgreSQL migration (`bin/rails migrate:from_mysql`)
- [x] SSH tunnel support for remote MySQL
- [x] Shell script alternative (`bin/migrate_from_rackspace`)
- [x] pgloader configuration (`lib/tasks/pgloader.load`)
- [x] Dependency ordering to handle foreign keys
- [x] Test connection task
- [ ] **Actual data migration not yet run**

### Phase 8: Kubernetes Deployment (100%)
- [x] Dockerfile configured for ARM64
- [x] k8s manifests created:
  - `k8s/deployment.yaml` - Rails app
  - `k8s/postgres.yaml` - PostgreSQL
  - `k8s/ingress.yaml` - Traefik ingress
  - `k8s/secrets.yaml.example` - Secrets template
  - `k8s/github-actions-sa.yaml` - CI/CD service account
- [x] GitHub Actions workflows:
  - `.github/workflows/docker-build.yml` - Build ARM64 image
  - `.github/workflows/deploy.yml` - Deploy to k3s
- [x] Cloudflare Tunnel config updated (in pistats repo)
- [ ] **Not yet deployed to cluster**

### Phase 9: Testing (0%)
- [ ] Model tests
- [ ] Controller tests
- [ ] System tests
- [ ] Integration tests

---

## Current State

The application is **feature-complete for MVP** but not yet deployed. The codebase is ready for:

1. **Database migration** from legacy MySQL
2. **Initial deployment** to k3s cluster
3. **Testing** in staging environment

### Local Development

The app runs locally with:
```bash
bin/dev  # Starts Rails + TailwindCSS watcher
```

Access at http://localhost:3000

---

## What's Left To Do

### High Priority (Before Go-Live)

1. **Run MySQL Migration**
   ```bash
   # Set up SSH tunnel to Rackspace
   ssh -L 3307:localhost:3306 user@rackspace-server -N

   # Run migration
   MYSQL_HOST=127.0.0.1 MYSQL_PORT=3307 bin/rails migrate:from_mysql
   ```

2. **Deploy to k3s**
   - Create secrets on cluster
   - Apply k8s manifests
   - Add Cloudflare DNS record for job509.polym.at
   - Verify deployment

3. **Create Admin Account**
   ```ruby
   Administrator.create!(name: 'admin', password: 'secure', role: :super)
   ```

4. **Test Core Flows**
   - User registration (job seeker & employer)
   - Job posting and approval
   - Job application
   - Resume creation
   - Admin panel functions

### Medium Priority

- Implement Twilio SMS sending in `bulk_sms` action
- Add comprehensive test suite
- Set up error monitoring (Sentry or similar)
- Configure production logging

### Low Priority (Future)

- Switch domain from job509.polym.at to job509.com
- Migrate Paperclip attachments to Active Storage (if legacy app has uploads)
- Performance optimization
- Add more API endpoints if needed

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `config/routes.rb` | All routes including API and admin |
| `app/models/user.rb` | Devise user with roles (job_seeker/employer) |
| `app/models/administrator.rb` | Admin auth with has_secure_password |
| `app/controllers/lakay/` | All admin controllers |
| `app/views/layouts/admin.html.erb` | Admin layout with sidebar |
| `lib/tasks/migrate_from_mysql.rake` | MySQL migration rake task |
| `k8s/` | Kubernetes manifests |
| `.github/workflows/` | CI/CD workflows |
| `config/locales/` | French and English translations |

---

## Related Projects

- **pistats** (`/Users/luc/code/personal/pistats`) - Pi cluster monitoring, shares Cloudflare Tunnel config
- **jobyola** (legacy) - Original Rails 2.3 app on Rackspace MySQL

---

## Commands Quick Reference

```bash
# Development
bin/dev                              # Start dev server
bin/rails console                    # Rails console
bin/rails routes                     # View routes

# Database
bin/rails db:migrate                 # Run migrations
bin/rails db:seed                    # Seed data

# Migration from MySQL
bin/rails migrate:from_mysql:test_connection  # Test MySQL connection
bin/rails migrate:from_mysql                  # Full migration

# Deployment
kubectl apply -f k8s/postgres.yaml   # Deploy PostgreSQL
kubectl apply -f k8s/deployment.yaml # Deploy Rails app
kubectl apply -f k8s/ingress.yaml    # Deploy ingress
kubectl rollout restart deployment/job509  # Restart app

# Logs
kubectl logs -f deployment/job509    # View Rails logs
```

---

## Notes for Next Session

When continuing this project, you may want to:

1. **Check deployment status**: `kubectl get pods -l app=job509`
2. **Review any errors**: `kubectl logs deployment/job509`
3. **Test the live site**: `curl https://job509.polym.at/up`

The main remaining work is:
- Running the actual MySQL data migration
- Deploying to the k3s cluster
- Testing in production environment
- Writing tests
