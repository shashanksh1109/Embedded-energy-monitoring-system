FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY target/energy-backend-1.0.0.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
