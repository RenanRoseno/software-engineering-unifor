FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace
COPY . .
RUN chmod +x gradlew && ./gradlew --no-daemon :services:audit-service:bootJar -x test

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /workspace/services/audit-service/build/libs/*.jar /app/app.jar
EXPOSE 8084
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
