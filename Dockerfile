# ==========================================
# STAGE 1: Build (The Compiler)
# ==========================================
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /backend

# Copy the pom.xml and source code
COPY pom.xml .
COPY src ./src

# Compile the code and package it into a .jar file
RUN mvn clean package -DskipTests

# ==========================================
# STAGE 2: Run (The Production Server)
# ==========================================
FROM eclipse-temurin:17-jre-alpine
WORKDIR /backend

# Pull the compiled .jar file from the builder stage
COPY --from=builder /backend/target/*.jar app.jar

ENV SERVER_PORT=7860
EXPOSE 7860

ENTRYPOINT ["java", "-jar", "app.jar"]