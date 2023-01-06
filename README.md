# General

Minimal example of a Spring Boot Java application with the steps necessary
to produce a docker image, a native image and a container image that runs
within Kubernetes.

* Uses new native support in Spring Boot 3.0.1
* Java 17 is required
* Steps and boilerplate to build and run service as Java JAR, Docker container
native executable or Kubernetes deployment.
* Docker needs to be set up if you want to build docker images
* The GRAALVM_HOME environment variable needs to be set to your local GraalVM 
installation if you want to build a native executable (search for GraalVM 
installation if you don't have it installed).

# Normal Build/Run

Package into jar:

```shell
mvn package
```

Run service:

```shell
java -jar target/spring-boot-native-0.0.2-SNAPSHOT.jar
```

You can verify service is up and healthy via:

```shell
curl http://localhost:8080/actuator/health; echo
```

## Build "fat" docker container image

```shell
mvn clean
mvn spring-boot:build-image
```

To check that this initial image will run the service:

```shell
docker run --rm -p 8080:8080 spring-boot-native:0.0.2-SNAPSHOT
```

NOTE: This container image is much bigger and starts much slower to start up
than either of the native images that are built later. Size is about 3X bigger:

```shell
[pabla@tamale spring-boot-native]$ docker image ls | grep spring-boot
spring-boot-native                                   v1                                             b59261d327c8   10 minutes ago   91.4MB
spring-boot-native                                   0.0.2-SNAPSHOT                                 a3dd76fc8785   43 years ago     277MB
[pabla@tamale spring-boot-native]$ 
```

# Native Build Instructions

Set the GRAALVM_HOME environment variable to the directory where you installed
GraalVM:

```shell
export GRAALVM_HOME=/home/pabla/.local/graalvm-ce-java17-22.3.0
```

Optionally set JAVA_HOME and PATH for the GraalVM tools:

```shell
export JAVA_HOME="${GRAALVM_HOME}"
export PATH="${GRAALVM_HOME}/bin:${PATH}"
```

## Build native docker container image

```shell
mvn clean
mvn -Pnative spring-boot:build-image
```

To check that this initial image will run the service:

```shell
docker run --rm -p 8080:8080 spring-boot-native:0.0.2-SNAPSHOT
```

## Build native executable

```shell
mvn -Pnative -DskipTests native:compile # Use "package" if Spring Boot 2.6.3
```

NOTE: You can run native executable directly:

```shell
./target/spring-boot-native
```

## Build final docker image from Native executable

Requires a target/spring-boot-native executable from prior build and a
[Dockerfile](Dockerfile).

```shell
docker build --tag spring-boot-native:v1 .
```

Run as docker container:

```shell
docker run --rm -p 8080:8080 spring-boot-native:v1
```

NOTE: This second pass is probably not worth it, the startup times and image
sizes are pretty close.

```shell
[pabla@tamale spring-boot-native]$ docker image ls | grep spring-boot
spring-boot-native                                   v1                                             b59261d327c8   7 minutes ago    91.4MB
spring-boot-native                                   0.0.2-SNAPSHOT                                 352876894e35   43 years ago     95.7MB
[pabla@tamale spring-boot-native]$ 
```

# Kubernetes (microk8s)

If you don't have a registry set up, you can save the docker container and then
import it into microk8s via:

```shell
docker image save spring-boot-native:v1 | microk8s ctr image import -
```

You can then generate a template deployment and service yaml file for kubernetes via:

```shell
kubectl create namespace demo -o=yaml --dry-run=client >| target/spring-boot-native.yaml
echo ---  >> target/spring-boot-native.yaml
kubectl create deployment spring-boot-native --namespace demo --image docker.io/library/spring-boot-native:v1 -o=yaml --dry-run=client >> target/spring-boot-native.yaml
echo --- >> target/spring-boot-native.yaml
kubectl create service clusterip course-tracker-service --namespace demo --tcp 80:8080 -o=yaml --dry-run=client >> target/spring-boot-native.yaml
```

To apply these yaml files to your Kubernetes cluster:

```shell
kubectl apply -f target/spring-boot-native.yaml
```

To expose the service port from Kubernetes:

```shell
kubectl port-forward --namespace demo deployment/spring-boot-native 8080:8080
```

You should then be able to curl the health of the service on the exposed port:

```shell
[pabla@tamale ~]$ curl http://localhost:8080/actuator/health; echo
{"status":"UP"}
[pabla@tamale ~]$
```

To remove from your cluster:

```shell
kubectl delete -f target/spring-boot-native.yaml
```
