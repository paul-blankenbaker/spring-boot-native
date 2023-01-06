FROM quay.io/quarkus/quarkus-distroless-image:2.0
WORKDIR /app
ADD target/spring-boot-native /app/spring-boot-native
CMD ["/app/spring-boot-native"]
#EXPOSE 8080
