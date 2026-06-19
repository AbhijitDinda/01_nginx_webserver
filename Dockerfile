# ==============================================================
# Dockerfile — Nginx Static Web Server
# Base: nginx:1.25-alpine (Alpine Linux ~23MB total image)
# Author: TechBridge India
# ==============================================================

# ── STAGE: Production Image ──────────────────────────────────
# We use nginx:1.25-alpine NOT nginx:latest because:
#   1. Alpine is minimal — only essential packages
#   2. nginx:1.25-alpine image = ~23MB vs nginx:latest = ~187MB
#   3. Alpine has fewer attack surfaces (security)
#   4. Pinning to 1.25 ensures reproducible builds
FROM nginx:1.30-alpine

# ── Metadata Labels ──────────────────────────────────────────
# Labels follow OCI (Open Container Initiative) standard
# Useful for image management and CI/CD tooling
LABEL org.opencontainers.image.title="TechBridge Nginx Web Server"
LABEL org.opencontainers.image.description="Static web server with HTML, CSS, JS, images and PDFs"
LABEL org.opencontainers.image.version="2.0.0"
LABEL org.opencontainers.image.authors="abhijitdinda228@example.com"
LABEL org.opencontainers.image.source="https://github.com/AbhijitDinda/01_nginx_webserver"

# ── Install additional tools (optional but useful) ────────────
# wget is used by our HEALTHCHECK
# We install and then clean up in same RUN to keep layer small
# apk = Alpine Package Manager (like apt for Ubuntu)
RUN apk add --no-cache wget \
    && rm -rf /var/cache/apk/*

# ── Remove default Nginx content ─────────────────────────────
# The base nginx image comes with a default "Welcome to Nginx" page
# We remove it before copying our own content
RUN rm -rf /usr/share/nginx/html/*

# ── Copy Nginx Configuration ──────────────────────────────────
# IMPORTANT: Copy config BEFORE website files
# nginx.conf = main global configuration
# conf.d/default.conf = server block (virtual host)
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# ── Copy Website Files ────────────────────────────────────────
# This copies everything inside website/ into /usr/share/nginx/html/
# Result inside container:
#   /usr/share/nginx/html/index.html
#   /usr/share/nginx/html/css/style.css
#   /usr/share/nginx/html/js/main.js
#   /usr/share/nginx/html/images/logo.png
#   /usr/share/nginx/html/docs/company-brochure.pdf
#   etc.
COPY website/ /usr/share/nginx/html/

# ── File Permissions ──────────────────────────────────────────
# Ensure Nginx process (user: nginx) can read all web files
# 755 = owner rwx, group r-x, others r-x (read + execute for dirs)
# 644 = owner rw-, group r--, others r-- (read-only for files)
RUN find /usr/share/nginx/html -type d -exec chmod 755 {} \; \
    && find /usr/share/nginx/html -type f -exec chmod 644 {} \;

# ── Validate Nginx Configuration ──────────────────────────────
# This runs nginx -t during BUILD time
# If nginx.conf has any syntax error, the build FAILS here
# Catches errors before deployment — crucial for CI/CD
RUN nginx -t

# ── Expose Port ───────────────────────────────────────────────
# EXPOSE is documentation metadata only
# It does NOT actually open the port
# The actual port mapping happens with: docker run -p 80:80
EXPOSE 80

# ── Health Check ──────────────────────────────────────────────
# Docker uses this to determine if the container is "healthy"
# --interval=30s  : check every 30 seconds
# --timeout=10s   : fail if no response within 10 seconds
# --start-period=5s : give Nginx 5 seconds to initialize first
# --retries=3     : mark UNHEALTHY after 3 consecutive failures
# The command: wget silently fetches localhost/
#   returns exit code 0 (success) if HTTP 200 received
#   returns exit code 1 (failure) if unreachable
HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=5s \
    --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# ── Default Command ───────────────────────────────────────────
# The official nginx image already sets:
#   CMD ["nginx", "-g", "daemon off;"]
# "daemon off" is CRITICAL for Docker:
#   Without it, Nginx would fork a background daemon and exit
#   Docker would think the container crashed and stop it
#   With "daemon off", Nginx stays in the FOREGROUND
#   Docker tracks the foreground process (PID 1)
# We explicitly set it here for clarity in teaching
CMD ["nginx", "-g", "daemon off;"]