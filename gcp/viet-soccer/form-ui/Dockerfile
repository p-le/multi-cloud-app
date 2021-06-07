FROM node:16-slim as react-build

WORKDIR /app
COPY . ./

RUN npm run build


FROM nginx:1.21-alpine

ENV PORT 8080

COPY nginx.conf /etc/nginx/conf.d/configfile.template
COPY --from=react-build /app/build /usr/share/nginx/html

# CMD sh -c "envsubst '\$PORT' < /etc/nginx/conf.d/configfile.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
