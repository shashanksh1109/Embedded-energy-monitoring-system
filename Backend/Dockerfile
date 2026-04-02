# ─────────────────────────────────────────────────────────────
# STAGE 1 — BUILD
#
# Multi-stage build keeps the final image small.
# Stage 1 uses a full Maven + JDK image to compile and package.
# Stage 2 uses a minimal JRE image just to run the JAR.
#
# Without multi-stage: ~600MB image (Maven + JDK + your code)
# With multi-stage:    ~200MB image (JRE + your JAR only)
# ─────────────────────────────────────────────────────────────
FROM maven:3.9.6-eclipse-temurin-17 AS builder

# Set working directory inside the container
WORKDIR /app

# Copy pom.xml first — before source code.
# Docker caches each layer. If pom.xml hasn't changed,
# Docker reuses the cached dependency download layer.
# Only re-downloads dependencies when pom.xml changes.
COPY pom.xml .

# Download all dependencies declared in pom.xml.
# -B = batch mode (no interactive prompts)
# dependency:go-offline = download everything needed to build offline
# This layer gets cached — subsequent builds are much faster.
RUN mvn -B dependency:go-offline

# Copy source code — after dependencies.
# Source changes more often than pom.xml.
# Keeping source copy after dependency download
# means source changes don't invalidate the dependency cache.
COPY src ./src

# Build the executable JAR.
# -DskipTests = skip tests during Docker build (tests run in CI)
# The JAR is created at: target/energy-backend-1.0.0.jar
RUN mvn -B package -DskipTests

# ─────────────────────────────────────────────────────────────
# STAGE 2 — RUN
#
# Start fresh from a minimal JRE image.
# None of the Maven tools or source code come with us —
# only the compiled JAR from Stage 1.
# ─────────────────────────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine

# Alpine = minimal Linux distribution (~5MB base)
# Much smaller than ubuntu or debian based images

WORKDIR /app

# Copy only the JAR from the builder stage.
# --from=builder = copy from Stage 1, not the local filesystem.
# target/*.jar = the compiled JAR file
COPY --from=builder /app/target/*.jar app.jar

# Expose port 8081 — the port Spring Boot listens on.
# This is documentation — it doesn't actually open the port.
# The port mapping in docker-compose.yml does that.
EXPOSE 8081

# Command to run when the container starts.
# java -jar app.jar = run the Spring Boot executable JAR
#
# JVM memory flags for container environments:
# -XX:+UseContainerSupport = respect container memory limits
# -XX:MaxRAMPercentage=75  = use max 75% of container RAM for heap
# Without these, JVM ignores Docker memory limits and can crash.
ENTRYPOINT ["java", \
            "-XX:+UseContainerSupport", \
            "-XX:MaxRAMPercentage=75.0", \
            "-jar", \
            "app.jar"]