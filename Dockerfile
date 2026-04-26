FROM tomcat:10.1-jdk17-openjdk-slim

# Default webapps remove karo (optional - clean install ke liye)
RUN rm -rf /usr/local/tomcat/webapps/*

# WAR file copy karo
COPY target/java17-mysql-webapp-1.0.war /usr/local/tomcat/webapps/ROOT.war

# Port expose karo
EXPOSE 8080

# Tomcat start karo
CMD ['catalina.sh', 'run']
