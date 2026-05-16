FROM maven:3.9-eclipse-temurin-17-alpine AS builder

ARG GITHUB_TOKEN
ARG GITHUB_ACTOR=x-access-token
ARG GITHUB_OWNER=GITHUB_ORG

WORKDIR /build

# GitHub Packages auth — core kütüphanesini çekmek için
RUN mkdir -p /root/.m2 && \
    printf '<settings><servers><server><id>github-core</id><username>%s</username><password>%s</password></server></servers></settings>' \
    "$GITHUB_ACTOR" "$GITHUB_TOKEN" > /root/.m2/settings.xml

COPY pom.xml .
RUN mvn dependency:go-offline -Dgithub.owner=${GITHUB_OWNER} -q

COPY src ./src
# -Dspring-boot.repackage.skip=false: pom.xml'deki <skip>true</skip> override edilir
RUN mvn package -DskipTests -Dspring-boot.repackage.skip=false -Dgithub.owner=${GITHUB_OWNER} -q

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar
EXPOSE 8002
ENTRYPOINT ["java", "-jar", "app.jar"]
