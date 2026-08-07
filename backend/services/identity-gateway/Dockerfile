FROM eclipse-temurin:21-jdk AS build
WORKDIR /workspace
COPY . .
RUN chmod +x gradlew && ./gradlew --no-daemon :services:identity-gateway:bootJar -x test

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /workspace/services/identity-gateway/build/libs/*.jar /app/app.jar
EXPOSE 8090
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
