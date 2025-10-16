FROM ${{values.dockerImagePrefix}}/openjdk-17-runtime:1.0-5-fk2
COPY target/${{values.javaArtifactId}}*-runner.jar /deployments/${{values.javaArtifactId}}.jar

WORKDIR /deployments
EXPOSE 8080
ENTRYPOINT ["java","-jar","${{values.javaArtifactId}}.jar"]