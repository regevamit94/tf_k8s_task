From Ubuntu:latest

RUN apt update && apt install nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]