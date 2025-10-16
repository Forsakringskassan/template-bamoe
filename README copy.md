# ${{values.applicationName}}
Processapplikation baserad på IBM BAMOE genererad utifrån mall. Denna exempelapplikation baseras på [process-business-rules-quarkus](https://github.com/apache/incubator-kie-kogito-examples/tree/main/kogito-quarkus-examples/process-business-rules-quarkus).  
  
Applikationen innehåller:
* En *BPMN process*
* En *DRL regel* som kontrollerar om en Person är över 18.
* *Java-kod* för att hålla värden som används i ovan process och regel.

Processen startar med att ta emot ett Person objekt. Ett maskinellt processteg använder DRL-regeln. Om Personen är över 18, avslutas processen. Om personen är mindre än 18, faller ett manuellt processteg ut och processen pausas, tills att man manuellt avslutar processen.

## Kompilera och kör Local Dev Mode
```sh
./mvnw clean compile quarkus:dev -s settings.xml
```

## Paketara och kör uber-jar-filen.
```sh
./mvnw clean package -s settings.xml
java -jar target/${{values.javaArtifactId}}*-runner.jar
```

## Bygg en image för Openshift

En docker-image kan byggas för att köras i Openshift-miljön. Säkerställ att du är inloggad i rätt Openshift-project. Skapa en build-config och kör ett bygge. Notera att du först måste byggt uber-jar-filen, enligt ovan.

```sh
./mvnw clean package
oc new-build --name ${{values.applicationName | lower}} --binary --strategy docker --to ${{values.applicationName | lower}}:v1
oc start-build ${{values.applicationName | lower}} --from-dir=. --follow
```
  
Om du vill bygga en ny version av imagen, byt versionstagg.
```sh
oc patch buildconfig/${{values.applicationName | lower}} --type=merge --patch '{"spec":{"output":{"to":{"name":"${{values.applicationName | lower}}:v2"}}}}'
oc start-build ${{values.applicationName | lower}} --from-dir=. --follow
```

## Deployment av processapplikationen på Openshift
Du behöver skapa upp Openshift infrastruktur för att köra docker-imagen. Det finns en färdig mall för att generera infrastruktur-koden i Utvecklarportalen, 
[Kogito-deployment](${{values.infrastructureTemplate}}).
  
## Applikationens gränssnitt
Applikationens [OpenAPI definition](http://localhost:8080/q/openapi?format=json) finns tillgänglig när applikationen kör. För ökad läsbarhet exponeras också 
[Swagger UI](http://localhost:8080/q/swagger-ui/) när applikationen för i dev-mode.

## Testa processapplikationen

Starta en processinstans för en vuxen.
```
curl -x "" -X POST -H 'Content-Type:application/json' -H 'Accept:application/json' -d '{"person" : {"name" : "john", "age" : 20}}' http://localhost:8080/persons
```

Säkerställ att processen har avslutats direkt.
```
curl -x "" http://localhost:8080/usertasks/instance?user=jdoe
```

Skapa en processinstans för ett barn.
```
curl -x "" -X POST -H 'Content-Type:application/json' -H 'Accept:application/json' -d '{"person" : {"name" : "john", "age" : 5}}' http://localhost:8080/persons
```

Kontroller att processen har startat och ännu inte avslutats.
```
curl -x "" http://localhost:8080/usertasks/instance?user=jdoe
```

Markera processen som klar. Använd det processinstansid som returneras ovan.
```
curl -x "" -X POST "http://localhost:8080/usertasks/instance/{id}/transition?user=jdoe" -H "content-type: application/json" -d '{"transitionId": "complete","data": {"approve": true}}'
```

Säkerställ att processen har avslutats, `... "terminate": "COMPLETED" ...`.
```
curl -x "" http://localhost:8080/usertasks/instance?user=jdoe
```