# Railway: builds the Flutter web app and serves it as static files.
# Set SUPABASE_URL / SUPABASE_ANON_KEY as Railway service variables (Railway
# passes them in as build args). Without them the build runs in mock mode.
FROM ghcr.io/cirruslabs/flutter:stable AS build
ARG SUPABASE_URL=""
ARG SUPABASE_ANON_KEY=""
WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .
RUN flutter build web --release \
      --dart-define=SUPABASE_URL=$SUPABASE_URL \
      --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# ponytail: Caddy serves static files + SPA fallback in 1 line; Railway injects $PORT.
FROM caddy:2-alpine
COPY --from=build /app/build/web /srv
CMD ["sh", "-c", "caddy file-server --root /srv --listen :${PORT:-8080} --try-files {path} /index.html"]
