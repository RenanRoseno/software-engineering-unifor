FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace
COPY . .
RUN chmod +x gradlew && ./gradlew --no-daemon :services:donor-service:bootJar -x test

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /workspace/services/donor-service/build/libs/*.jar /app/app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
