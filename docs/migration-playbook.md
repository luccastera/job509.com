# Migration Playbook: job509.com from Rackspace to k3s

**Goal:** Migrate the production job509.com site from a legacy Rails 2.3 app on Rackspace (MySQL) to the new Rails 8.1.1 app running on Raspberry Pi 5 k3s cluster (PostgreSQL), with DNS transfer to DNSimple and Cloudflare Tunnel routing.

**Architecture:**

```
Legacy:  job509.com → Rackspace → Rails 2.3 + MySQL

Target:  job509.com → Cloudflare CDN → Cloudflare Tunnel → k3s (Pi 5) → Traefik → Rails 8.1.1 + PostgreSQL
```

---

## Pre-Migration Checklist

Complete all items before starting Phase 1.

### Access Verification

- [ ] SSH into Rackspace: `ssh user@rackspace-server`
- [ ] MySQL access on Rackspace: `mysql -u root jobyola_production -e "SELECT COUNT(*) FROM users"`
- [ ] SSH into Pi: `ssh pi5luc`
- [ ] kubectl works: `ssh pi5luc "sudo kubectl get nodes"`
- [ ] Cloudflare Zero Trust dashboard access at https://one.dash.cloudflare.com/
- [ ] DNSimple account access at https://dnsimple.com/
- [ ] GHCR access: `docker login ghcr.io`

### Inventory Legacy Data

Record current counts from Rackspace MySQL for post-migration verification:

```bash
ssh user@rackspace-server "mysql -u root jobyola_production -e '
  SELECT \"users\" AS tbl, COUNT(*) AS cnt FROM users
  UNION ALL SELECT \"jobs\", COUNT(*) FROM jobs
  UNION ALL SELECT \"resumes\", COUNT(*) FROM resumes
  UNION ALL SELECT \"applics\", COUNT(*) FROM applics
  UNION ALL SELECT \"educations\", COUNT(*) FROM educations
  UNION ALL SELECT \"work_experiences\", COUNT(*) FROM work_experiences
  UNION ALL SELECT \"skills\", COUNT(*) FROM skills
  UNION ALL SELECT \"language_skills\", COUNT(*) FROM language_skills
  UNION ALL SELECT \"referrals\", COUNT(*) FROM referrals
  UNION ALL SELECT \"events\", COUNT(*) FROM events
  UNION ALL SELECT \"attendees\", COUNT(*) FROM attendees
  UNION ALL SELECT \"countries\", COUNT(*) FROM countries
  UNION ALL SELECT \"cities\", COUNT(*) FROM cities
  UNION ALL SELECT \"sectors\", COUNT(*) FROM sectors
  UNION ALL SELECT \"jobtypes\", COUNT(*) FROM jobtypes
  UNION ALL SELECT \"languages\", COUNT(*) FROM languages
  UNION ALL SELECT \"tags\", COUNT(*) FROM tags
  UNION ALL SELECT \"taggings\", COUNT(*) FROM taggings
  UNION ALL SELECT \"lists\", COUNT(*) FROM lists
  UNION ALL SELECT \"coupons\", COUNT(*) FROM coupons
  UNION ALL SELECT \"featured_recruiters\", COUNT(*) FROM featured_recruiters
  UNION ALL SELECT \"share_tokens\", COUNT(*) FROM share_tokens;
'"
```

Save the output — you'll compare against it after migration.

### Identify Legacy File Uploads

Check if the legacy app has file uploads (likely Paperclip):

```bash
ssh user@rackspace-server "find /path/to/jobyola/public/system -type f | head -20"
ssh user@rackspace-server "du -sh /path/to/jobyola/public/system"
```

Note the path and total size for Phase 2.

### Take Backups

```bash
# Full MySQL dump from Rackspace
ssh user@rackspace-server "mysqldump -u root jobyola_production | gzip > /tmp/jobyola_backup_$(date +%Y%m%d).sql.gz"
scp user@rackspace-server:/tmp/jobyola_backup_*.sql.gz ~/backups/

# Snapshot current k3s PostgreSQL (if any data exists)
ssh pi5luc "sudo kubectl exec deployment/job509-postgres -- \
  pg_dump -U job509 job509_production | gzip > /tmp/pg_backup_$(date +%Y%m%d).sql.gz"
```

---

## Phase 1: Database Migration (MySQL → PostgreSQL)

**Duration estimate:** 30–60 minutes depending on data volume

### 1.1 Ensure the k3s App is Deployed

The Rails app and PostgreSQL must already be running on the cluster. If not yet deployed, follow `docs/deployment.md` first, then return here.

Verify:

```bash
ssh pi5luc "sudo kubectl get pods -l app=job509"
ssh pi5luc "sudo kubectl get pods -l app=job509-postgres"
curl -s -o /dev/null -w "%{http_code}" https://job509.polym.at/up
# Should return 200
```

### 1.2 Set Up SSH Tunnel to Rackspace MySQL

Open a **dedicated terminal** — keep this running throughout the migration:

```bash
ssh -L 3307:localhost:3306 user@rackspace-server -N
```

Verify the tunnel:

```bash
mysql -h 127.0.0.1 -P 3307 -u root jobyola_production -e "SELECT COUNT(*) FROM users"
```

### 1.3 Prepare Local Environment

```bash
cd /Users/luc/code/personal/job509.com

# Ensure mysql2 gem is available (it's in the development group)
bundle install

# Ensure local PostgreSQL has the schema
bin/rails db:migrate
```

### 1.4 Test MySQL Connection via Rake

```bash
export MYSQL_HOST=127.0.0.1
export MYSQL_PORT=3307
export MYSQL_DATABASE=jobyola_production
export MYSQL_USERNAME=root
export MYSQL_PASSWORD=""

bin/rails migrate:from_mysql:test_connection
```

Expected output: table counts for all tables. Compare against your inventory from the pre-migration checklist.

### 1.5 Check Dependencies

```bash
bin/rails migrate:from_mysql:check_dependencies
```

This will report missing dependencies. On a fresh database, everything will show as empty — that's expected before migration starts.

### 1.6 Run the Full Migration

Run all migration tasks in dependency order:

```bash
bin/rails migrate:from_mysql
```

This runs the following in order:
1. **Lookup tables** — countries, cities, sectors, jobtypes, languages
2. **Users** — all user accounts (passwords set to random values)
3. **Jobs** — job postings (skips jobs whose employer doesn't exist)
4. **Resumes** — resumes + educations, work experiences, skills, language skills, referrals
5. **Applications** — job applications (skips if user or job doesn't exist)
6. **Events** — events and attendees
7. **Admin data** — tags, taggings, lists, coupons, featured recruiters, share tokens

If a step fails, you can re-run individual tasks:

```bash
bin/rails migrate:from_mysql:lookup_tables
bin/rails migrate:from_mysql:users
bin/rails migrate:from_mysql:jobs
bin/rails migrate:from_mysql:resumes
bin/rails migrate:from_mysql:applications
bin/rails migrate:from_mysql:events
bin/rails migrate:from_mysql:admin
```

Each task is idempotent — it uses `find_or_create_by!` and skips existing records.

### 1.7 Verify Record Counts

```bash
bin/rails runner "
  %w[Country City Sector Jobtype Language User Job Resume Education
     WorkExperience Skill LanguageSkill Referral Applic Event Attendee
     Tag Tagging List Coupon FeaturedRecruiter ShareToken].each do |m|
    puts \"#{m}: #{m.constantize.count}\"
  end
"
```

Compare against your pre-migration inventory. Some records may have been skipped due to invalid emails or missing foreign keys — review the migration output for skip reasons.

### 1.8 Create Administrator Accounts

Admin accounts are NOT migrated (different password hashing). Create them manually:

```bash
bin/rails runner "
  Administrator.create!(name: 'admin', password: 'CHANGE_ME_IMMEDIATELY', role: :super)
  puts 'Administrator created successfully'
"
```

### 1.9 Export the Migrated Database to k3s

The migration ran against your local PostgreSQL. Now export and import into the k3s cluster:

```bash
# Dump local database
pg_dump job509_com_development | gzip > /tmp/job509_migrated.sql.gz

# Transfer to Pi
scp /tmp/job509_migrated.sql.gz pi5luc:/tmp/

# Get the postgres pod name
PGPOD=$(ssh pi5luc "sudo kubectl get pods -l app=job509-postgres -o jsonpath='{.items[0].metadata.name}'")

# Copy dump into the pod
ssh pi5luc "gunzip /tmp/job509_migrated.sql.gz"
ssh pi5luc "sudo kubectl cp /tmp/job509_migrated.sql ${PGPOD}:/tmp/job509_migrated.sql"

# Drop and recreate the production database, then import
ssh pi5luc "sudo kubectl exec ${PGPOD} -- bash -c '
  psql -U job509 -d postgres -c \"DROP DATABASE IF EXISTS job509_production;\"
  psql -U job509 -d postgres -c \"CREATE DATABASE job509_production;\"
  psql -U job509 -d job509_production < /tmp/job509_migrated.sql
'"

# Restart the Rails app to pick up new data
ssh pi5luc "sudo kubectl rollout restart deployment/job509"
ssh pi5luc "sudo kubectl rollout status deployment/job509 --timeout=300s"
```

### Phase 1 Rollback

If the migration produced bad data:

```bash
# Reset local database
bin/rails db:drop db:create db:migrate

# Or restore k3s from backup
ssh pi5luc "sudo kubectl exec ${PGPOD} -- bash -c '
  psql -U job509 -d postgres -c \"DROP DATABASE IF EXISTS job509_production;\"
  psql -U job509 -d postgres -c \"CREATE DATABASE job509_production;\"
'"
ssh pi5luc "sudo kubectl rollout restart deployment/job509"
```

The legacy Rackspace database is untouched — you can always re-run the migration.

---

## Phase 2: File Upload Migration

**Skip this phase if the legacy app has no file uploads.**

### 2.1 Download Uploads from Rackspace

```bash
# Create a local directory for legacy uploads
mkdir -p /tmp/legacy_uploads

# SCP the Paperclip uploads directory
scp -r user@rackspace-server:/path/to/jobyola/public/system/ /tmp/legacy_uploads/
```

### 2.2 Attach Files via Active Storage

Active Storage files are stored on disk at `/rails/storage` in the k3s pod (1Gi PVC).

Write a rake task or Rails runner script to process uploads. Example for event images:

```bash
bin/rails runner "
  Dir.glob('/tmp/legacy_uploads/system/events/**/*').select { |f| File.file?(f) }.each do |file|
    # Extract event ID from the path (adjust based on Paperclip path structure)
    event_id = file.match(/events\/(\d+)/)[1].to_i rescue next
    event = Event.find_by(id: event_id)
    next unless event

    event.image.attach(
      io: File.open(file),
      filename: File.basename(file),
      content_type: Marcel::MimeType.for(Pathname.new(file))
    )
    puts \"Attached image to Event ##{event_id}\"
  end
"
```

Adapt the script based on which models have attachments in the legacy app.

### 2.3 Sync Uploads to k3s

The Active Storage files are in your local `storage/` directory. Transfer them to the pod:

```bash
# Get the Rails pod name
RAILSPOD=$(ssh pi5luc "sudo kubectl get pods -l app=job509 -o jsonpath='{.items[0].metadata.name}'")

# Copy storage directory contents
tar -czf /tmp/active_storage.tar.gz -C storage .
scp /tmp/active_storage.tar.gz pi5luc:/tmp/
ssh pi5luc "sudo kubectl cp /tmp/active_storage.tar.gz ${RAILSPOD}:/rails/storage/active_storage.tar.gz"
ssh pi5luc "sudo kubectl exec ${RAILSPOD} -- tar -xzf /rails/storage/active_storage.tar.gz -C /rails/storage/"
ssh pi5luc "sudo kubectl exec ${RAILSPOD} -- rm /rails/storage/active_storage.tar.gz"
```

### Phase 2 Rollback

Delete Active Storage records and re-run:

```bash
bin/rails runner "ActiveStorage::Attachment.destroy_all; ActiveStorage::Blob.destroy_all"
```

---

## Phase 3: Verification on job509.polym.at

Run through these checks on the live staging URL before touching DNS.

### 3.1 Health & Connectivity

```bash
# Health check endpoint
curl -I https://job509.polym.at/up

# Homepage loads
curl -s https://job509.polym.at | head -20

# Check response headers
curl -sI https://job509.polym.at | grep -i "x-request-id\|server\|content-type"
```

### 3.2 Data Integrity Spot Checks

```bash
# Open Rails console on the cluster
ssh pi5luc "sudo kubectl exec -it deployment/job509 -- bin/rails console"
```

In the console:

```ruby
# Verify counts
puts "Users: #{User.count}"
puts "Jobs: #{Job.count}"
puts "Resumes: #{Resume.count}"
puts "Applications: #{Applic.count}"

# Verify a few specific records
User.first
Job.where(approved: true).last
Resume.includes(:educations, :work_experiences).first

# Verify associations
user = User.where(role: :employer).first
puts "Employer #{user.email} has #{user.jobs.count} jobs"

user = User.where(role: :job_seeker).first
puts "Job seeker #{user.email} has #{user.resume&.educations&.count || 0} educations"
```

### 3.3 User Flow Testing

Test each flow in a browser at https://job509.polym.at:

- [ ] **Homepage** — loads, shows recent jobs
- [ ] **Job listing** — `/emplois` loads, pagination works
- [ ] **Job detail** — click a job, full detail page renders
- [ ] **Job search** — filter by sector, city, jobtype
- [ ] **Job seeker signup** — `/signup` creates account
- [ ] **Employer signup** — `/emp_signup` creates account
- [ ] **Login** — `/login` with a test account
- [ ] **Resume builder** — create/edit resume sections
- [ ] **Job application** — apply to a job as a job seeker
- [ ] **Employer dashboard** — view posted jobs, see applicants
- [ ] **PDF resume** — download generates a PDF
- [ ] **Events page** — `/evenements` lists events
- [ ] **Static pages** — About, FAQ, Contact render correctly
- [ ] **RSS feed** — `/emplois.rss` returns valid XML
- [ ] **Sitemap** — `/sitemap.xml` returns valid XML
- [ ] **API** — `curl https://job509.polym.at/api/jobs` returns JSON

### 3.4 Admin Panel

- [ ] **Admin login** — https://job509.polym.at/lakay/login
- [ ] **Dashboard** — shows statistics
- [ ] **Job management** — list, approve, edit jobs
- [ ] **Job seeker management** — search, view, tag users
- [ ] **Employer management** — list employers
- [ ] **Applications** — view applications
- [ ] **Events** — list, edit events
- [ ] **Tags/Lists/Coupons** — CRUD operations work

### Phase 3 Rollback

If critical issues are found, fix them before proceeding. The legacy site on Rackspace is still serving traffic — no user impact.

---

## Phase 4: DNS Transfer to DNSimple

Transfer the `job509.com` domain from Rackspace DNS to DNSimple.

### 4.1 Document Current DNS Records

Before making changes, capture all existing DNS records for `job509.com`:

```bash
dig job509.com ANY +short
dig www.job509.com ANY +short
dig mx job509.com +short
```

Save this output as your rollback reference.

### 4.2 Add Domain to DNSimple

1. Log in to https://dnsimple.com/
2. Go to **Domains** → **Add a Domain**
3. Enter `job509.com`
4. Choose **DNS only** (don't transfer registrar yet if it's separate from DNS hosting)

### 4.3 Recreate DNS Records in DNSimple

Add all existing DNS records from step 4.1 into DNSimple. For now, point the A record to the current Rackspace IP so the site stays live during the transition:

```
A     @              → <rackspace-ip>    (temporary, will change in Phase 5)
CNAME www            → job509.com        (or wherever www pointed)
MX    @              → <mail-server>     (if applicable)
TXT   @              → <any SPF/DKIM>    (if applicable)
```

### 4.4 Update Nameservers

At your domain registrar, update the nameservers for `job509.com` to DNSimple's nameservers:

```
ns1.dnsimple.com
ns2.dnsimple-edge.net
ns3.dnsimple.com
ns4.dnsimple-edge.org
```

### 4.5 Verify DNS Propagation

```bash
# Check nameservers
dig job509.com NS +short

# Verify site still resolves
dig job509.com A +short
curl -I https://job509.com
```

DNS propagation can take up to 48 hours. Wait until the old Rackspace nameservers are fully replaced before proceeding to Phase 5.

### Phase 4 Rollback

Revert nameservers at the registrar back to Rackspace's nameservers. DNS will re-propagate within TTL (usually 1–48 hours).

---

## Phase 5: Route job509.com Through Cloudflare Tunnel

Once DNS is on DNSimple and propagated, switch job509.com to route through the Cloudflare Tunnel to your k3s cluster.

### 5.1 Add job509.com to Cloudflare

1. Go to https://dash.cloudflare.com/
2. **Add a Site** → enter `job509.com`
3. Select the **Free** plan
4. Cloudflare will scan existing DNS records — review and confirm them
5. Cloudflare will give you new nameservers

### 5.2 Update Nameservers to Cloudflare

At DNSimple (or your registrar), update nameservers to Cloudflare's:

```
# Cloudflare will provide specific nameservers like:
# e.g., ada.ns.cloudflare.com
#       bob.ns.cloudflare.com
```

Wait for propagation:

```bash
dig job509.com NS +short
# Should show cloudflare nameservers
```

### 5.3 Add Public Hostname in Cloudflare Tunnel

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com/)
2. Navigate to **Networks** → **Tunnels**
3. Click tunnel `aaa2e315-4ded-4ff5-a0e6-8d0965f02d42`
4. Go to **Public Hostname** tab → **Add a public hostname**
5. Configure:
   - **Subdomain**: (leave blank for apex)
   - **Domain**: `job509.com`
   - **Type**: `HTTP`
   - **URL**: `job509-service.default.svc.cluster.local:80`
6. Add another for `www`:
   - **Subdomain**: `www`
   - **Domain**: `job509.com`
   - **Type**: `HTTP`
   - **URL**: `job509-service.default.svc.cluster.local:80`

### 5.4 Update DNS Records in Cloudflare

In the Cloudflare DNS dashboard for `job509.com`, replace the A record with a CNAME pointing to the tunnel:

```
CNAME  @    → aaa2e315-4ded-4ff5-a0e6-8d0965f02d42.cfargotunnel.com  (Proxied)
CNAME  www  → aaa2e315-4ded-4ff5-a0e6-8d0965f02d42.cfargotunnel.com  (Proxied)
```

Ensure the proxy status is **Proxied** (orange cloud), not DNS-only.

### 5.5 Configure SSL/TLS in Cloudflare

1. Go to **SSL/TLS** → **Overview**
2. Set mode to **Full**
3. Under **Edge Certificates**, enable:
   - **Always Use HTTPS**: On
   - **Automatic HTTPS Rewrites**: On

### 5.6 Update Traefik Ingress

Add `job509.com` as an additional host rule:

Edit `k8s/ingress.yaml` to include both hosts:

```yaml
spec:
  ingressClassName: traefik
  rules:
  - host: job509.polym.at
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: job509-service
            port:
              number: 80
  - host: job509.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: job509-service
            port:
              number: 80
  tls:
  - hosts:
    - job509.polym.at
    - job509.com
```

Apply:

```bash
cat k8s/ingress.yaml | ssh pi5luc "sudo kubectl apply -f -"
```

### 5.7 Update Rails Configuration

Update `config/environments/production.rb` to allow the new host and set the correct mailer URL:

```ruby
# Allow both hosts
config.hosts << "job509.com"
config.hosts << "job509.polym.at"

# Set mailer host
config.action_mailer.default_url_options = { host: "job509.com" }
```

Rebuild and redeploy:

```bash
# Build
docker buildx build --platform linux/arm64 \
  -t ghcr.io/luccastera/job509:latest \
  --output type=docker,dest=/tmp/job509-arm64.tar .

# Transfer and import
scp /tmp/job509-arm64.tar pi5luc:/tmp/
ssh pi5luc "sudo k3s ctr images import /tmp/job509-arm64.tar"

# Restart
ssh pi5luc "sudo kubectl rollout restart deployment/job509"
ssh pi5luc "sudo kubectl rollout status deployment/job509 --timeout=300s"
```

### 5.8 Verify

```bash
curl -I https://job509.com
curl -I https://www.job509.com
curl -I https://job509.com/up
curl -I https://job509.polym.at/up
```

All should return `200 OK`.

### Phase 5 Rollback

1. In Cloudflare DNS, change the CNAME back to an A record pointing to Rackspace IP
2. Remove the public hostname from Cloudflare Tunnel
3. Revert the ingress.yaml change and redeploy

---

## Phase 6: Final Cutover & Decommission Rackspace

### 6.1 Final Data Sync (Optional)

If time has passed since Phase 1, new data may have been created on the legacy site. Run a delta migration:

```bash
# Open SSH tunnel
ssh -L 3307:localhost:3306 user@rackspace-server -N

# In another terminal, check for new records
export MYSQL_HOST=127.0.0.1 MYSQL_PORT=3307 MYSQL_DATABASE=jobyola_production MYSQL_USERNAME=root MYSQL_PASSWORD=""

bin/rails runner "
  require 'mysql2'
  client = Mysql2::Client.new(host: '127.0.0.1', port: 3307, database: 'jobyola_production', username: 'root')
  cutover_date = '2026-03-01'  # adjust to your Phase 1 date
  %w[users jobs resumes applics].each do |t|
    result = client.query(\"SELECT COUNT(*) as cnt FROM #{t} WHERE created_at > '#{cutover_date}'\")
    puts \"#{t}: #{result.first['cnt']} new records since cutover\"
  end
"
```

If significant new data exists, re-run the migration tasks — they're idempotent and will skip existing records.

### 6.2 Notify Users

Users will need to reset their passwords because legacy password hashes are incompatible with Devise/bcrypt.

Options:
- Send a mass password reset email via `bin/rails runner`
- Add a banner on the login page explaining the reset
- Pre-generate reset tokens and email links

### 6.3 Monitor for 1–2 Weeks

Before decommissioning Rackspace, monitor the new site:

```bash
# Check pod health
ssh pi5luc "sudo kubectl get pods -l app=job509"

# Check recent logs for errors
ssh pi5luc "sudo kubectl logs deployment/job509 --tail=100 | grep -i error"

# Check resource usage
ssh pi5luc "sudo kubectl top pods -l app=job509"
```

Watch for:
- 5xx errors in logs
- Pod restarts (OOMKilled, CrashLoopBackOff)
- Slow response times
- Missing data or broken features

### 6.4 Decommission Rackspace

Once confident the new site is stable:

1. **Take a final backup** of the Rackspace MySQL database
2. **Download any remaining files** you haven't migrated
3. **Shut down the legacy app** (don't delete the server yet)
4. **Wait another week** to ensure nothing breaks
5. **Cancel the Rackspace server** when fully confident

```bash
# Final backup
ssh user@rackspace-server "mysqldump -u root jobyola_production | gzip > /tmp/jobyola_final_$(date +%Y%m%d).sql.gz"
scp user@rackspace-server:/tmp/jobyola_final_*.sql.gz ~/backups/
```

### 6.5 Clean Up

- [ ] Remove `job509.polym.at` public hostname from Cloudflare Tunnel (optional — can keep as alias)
- [ ] Remove old DNS records from DNSimple (if any remain pointing to Rackspace)
- [ ] Archive the legacy `jobyola` codebase
- [ ] Update `STATUS.md` to reflect the completed migration

### Phase 6 Rollback

If critical issues appear after cutover:

1. Re-point `job509.com` DNS to Rackspace IP (either in Cloudflare or by reverting nameservers)
2. Restart the legacy app on Rackspace
3. Investigate and fix issues on the k3s deployment
4. Re-attempt cutover when ready

---

## Quick Reference

### Useful Commands

```bash
# k3s cluster
ssh pi5luc "sudo kubectl get pods"
ssh pi5luc "sudo kubectl logs deployment/job509 --tail=50"
ssh pi5luc "sudo kubectl exec -it deployment/job509 -- bin/rails console"
ssh pi5luc "sudo kubectl exec -it deployment/job509-postgres -- psql -U job509 job509_production"

# Restart Rails app
ssh pi5luc "sudo kubectl rollout restart deployment/job509"

# Rebuild and deploy
docker buildx build --platform linux/arm64 -t ghcr.io/luccastera/job509:latest --output type=docker,dest=/tmp/job509-arm64.tar .
scp /tmp/job509-arm64.tar pi5luc:/tmp/
ssh pi5luc "sudo k3s ctr images import /tmp/job509-arm64.tar"
ssh pi5luc "sudo kubectl rollout restart deployment/job509"
```

### Key Files

| File | Purpose |
|------|---------|
| `lib/tasks/migrate_from_mysql.rake` | MySQL → PostgreSQL migration tasks |
| `k8s/deployment.yaml` | Rails app deployment + service + PVC |
| `k8s/postgres.yaml` | PostgreSQL deployment + service + PVC |
| `k8s/ingress.yaml` | Traefik ingress rules |
| `config/environments/production.rb` | Production Rails config |
| `docs/deployment.md` | Detailed deployment guide |

### Key URLs

| URL | Purpose |
|-----|---------|
| https://job509.polym.at | Staging / temporary production |
| https://job509.polym.at/up | Health check endpoint |
| https://job509.polym.at/lakay | Admin panel |
| https://one.dash.cloudflare.com/ | Cloudflare Zero Trust (tunnel config) |
| https://dash.cloudflare.com/ | Cloudflare DNS |

### Cloudflare Tunnel

- **Tunnel ID:** `aaa2e315-4ded-4ff5-a0e6-8d0965f02d42`
- **Service URL:** `job509-service.default.svc.cluster.local:80`
- **Managed via:** Cloudflare Zero Trust dashboard (remote config)
